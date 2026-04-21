from fastapi import FastAPI, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from transformers import CLIPProcessor, CLIPModel
from PIL import Image
import torch
import torch.nn.functional as F
import io
import firebase_admin
from firebase_admin import credentials, firestore, storage
from ultralytics import YOLO  #, FastSAM
import os
import json

# Check if is in the cloud, look for secret variable
firebase_secret = os.environ.get("FIREBASE_KEY_JSON")

if firebase_secret:
    print("Cloud Mode: Using Firebase credentials from Environment Variable.")
    cred_dict = json.loads(firebase_secret)
    cred = credentials.Certificate(cred_dict)
else:
    print("Local Mode: Using local firebase-key.json file.")
    cred = credentials.Certificate("firebase-key.json")

# Initialize Firebase
firebase_admin.initialize_app(cred, {
    'storageBucket': 'kampar-tour-guide-app.firebasestorage.app'
})

db = firestore.client()
bucket = storage.bucket()

device = "cuda" if torch.cuda.is_available() else "cpu"
print("Using device:", device)

app = FastAPI()

# Allow requests from Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load Models
print("Loading FastSAM model...")
fastsam_model = YOLO("FastSAM-s.pt").to(device)

print("Loading CLIP model...")
clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32").to(device)
processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32") # use_fast=False

attraction_metadata = {}

# Fetch from Firebase
def load_reference_images(base_prefix="reference_images/"):
    print("Crawling Firebase Storage for reference images...")
    
    dynamic_refs = {}
    
    blobs = bucket.list_blobs(prefix=base_prefix)

    for blob in blobs:
        if not blob.name.lower().endswith((".jpg", ".jpeg", ".png")):
            continue

        # Split the path: reference_images / place / label / filename
        parts = blob.name.split('/')
        
        if len(parts) >= 4:
            place = parts[1]  
            label = parts[2] 
            
            if place not in dynamic_refs:
                dynamic_refs[place] = {}
            if label not in dynamic_refs[place]:
                dynamic_refs[place][label] = []
            
            # Download and process the image
            try:
                img_data = blob.download_as_bytes()
                img = Image.open(io.BytesIO(img_data)).convert("RGB")
                img.load()
                dynamic_refs[place][label].append(img)
                print(f"Loaded: {place} -> {label} ({blob.name})")
            except Exception as e:
                print(f"Failed to load {blob.name}: {e}")

    return dynamic_refs

def load_text_prompts():
    print("Crawling Firestore for text prompts...")
    dynamic_text = {}
    global attraction_metadata 

    places_docs = db.collection("places").stream()

    for place_doc in places_docs:
        place_id = place_doc.id 
        dynamic_text[place_id] = {}
        attraction_metadata[place_id] = {}

        attractions = db.collection("places").document(place_id).collection("attractions").stream()
        
        for attr_doc in attractions:
            data = attr_doc.to_dict()
            doc_id = attr_doc.id 
            
            if "text_prompt" in data:
                dynamic_text[place_id][doc_id] = data["text_prompt"]
                print(f"Loaded Text: {place_id} -> {doc_id}")
            
            attraction_metadata[place_id][doc_id] = {
                "display_label": data.get("label", doc_id), 
                "url": data.get("url", "")
            }

    return dynamic_text

# Get reference images and texts
reference_paths = load_reference_images()
text_prompts = load_text_prompts()

# Compute Embeddings
reference_embeddings = {}
text_embeddings = {}

# Process Images
for place, labels in reference_paths.items():
    reference_embeddings[place] = {}
    for label, images in labels.items():
        if not images: continue
        inputs = processor(images=images, return_tensors="pt", padding=True).to(device)
        with torch.no_grad():
            features = clip_model.get_image_features(**inputs)

            if not isinstance(features, torch.Tensor):
                features = features.pooler_output

            # normalize embeddings
            features = F.normalize(features, dim=-1)
        reference_embeddings[place][label] = features

# Process Text
for place, labels in text_prompts.items():
    text_embeddings[place] = {}
    for label, text in labels.items():
        inputs = processor(text=[text], return_tensors="pt").to(device)
        with torch.no_grad():            
            features = clip_model.get_text_features(**inputs)

            if not isinstance(features, torch.Tensor):
                features = features.pooler_output

            features = F.normalize(features, dim=-1)
        text_embeddings[place][label] = features

print("Model and references loaded.")

# CLIP
def clip_prediction(cropped_img, place_id):
    inputs = processor(images=cropped_img, return_tensors="pt").to(device)

    with torch.no_grad():
        vision_outputs = clip_model.vision_model(**inputs)
        image_feature = clip_model.visual_projection(vision_outputs.pooler_output)
        image_feature = F.normalize(image_feature, dim=-1)

    similarities = {}
    for label in reference_embeddings[place_id]:
        ref_embeds = reference_embeddings[place_id][label]
        txt_embed = text_embeddings[place_id][label]

        # Compare with reference images
        image_sims = F.cosine_similarity(image_feature, ref_embeds)
        image_sim = image_sims.max().item()

        # Compare with text prompt
        text_sim = F.cosine_similarity(image_feature, txt_embed).item()

        # Weighted score 
        combined_score = 0.6 * image_sim + 0.4 * text_sim
        similarities[label] = combined_score

    best_label = max(similarities, key=similarities.get)
    return best_label, similarities[best_label]

# API Endpoint for Prediction
@app.post("/predict")
async def predict(
    place: str = Form(...),
    file: UploadFile = File(...)
):
    print(f"Request from place: {place}")

    if place not in reference_embeddings:
        return {"error": "Place not found"}

    image_bytes = await file.read()
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    width, height = img.size

    # Run detection
    fastsam_results = fastsam_model(img, conf=0.6, iou=0.45) 
    print(f"DEBUG: Found {len(fastsam_results[0].boxes)} objects.")
    
    best_detections = {}

    if place == "utar_grand_hall":
        MATCH_THRESHOLD = 0.55

    elif place == "kampar_seng_fatt_temple":
        MATCH_THRESHOLD = 0.6

    else:
        MATCH_THRESHOLD = 0.6

    # Process each detected bounding box
    for result in fastsam_results[0].boxes:
        box = result.xyxy[0].tolist()
        cropped_obj = img.crop((box[0], box[1], box[2], box[3]))
        
        # Identify object
        detected_id, score = clip_prediction(cropped_obj, place)

        if score >= MATCH_THRESHOLD:
            if detected_id not in best_detections or score > best_detections[detected_id]["score"]:
                
                meta = attraction_metadata.get(place, {}).get(detected_id, {})
                display_label = meta.get("display_label", detected_id)
                url = meta.get("url", "")

                best_detections[detected_id] = {
                    "id": detected_id,           
                    "label": display_label,      
                    "url": url,                 
                    "score": round(score, 4),
                    "box": [
                        box[0] / width,  
                        box[1] / height, 
                        box[2] / width, 
                        box[3] / height  
                    ]
                }
    
    # Convert the dictionary values back to a list
    final_list = list(best_detections.values())
    print(f"FINAL DETECTIONS TO SEND: {final_list}")

    return {
        "place": place,
        "detections": final_list
    }
