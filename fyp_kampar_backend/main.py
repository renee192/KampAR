from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from transformers import CLIPProcessor, CLIPModel
from PIL import Image
import torch
import torch.nn.functional as F
import io

app = FastAPI()

# Allow requests from Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to app's domain 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load Model & References at Startup
print("Loading CLIP model...")
model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")

# Reference image paths
reference_paths = {
    "inkblocks": [
        "Images/Dewan/inkblocks_close.jpg",
        "Images/Dewan/inkblocks_detail.jpg",
        "Images/Dewan/inkblocks_detail_water.jpg",
        "Images/Dewan/inkblocks_far.jpg",
        "Images/Dewan/inkblocks_far1.jpg",
        "Images/Dewan/inkblocks_far2.jpg",
        "Images/Dewan/inkblocks_near.jpg",
        "Images/Dewan/inkblocks_side.jpg",
        "Images/Dewan/inkblocks_side_far.jpg",
        "Images/Dewan/inkblocks_side_near.jpg",
        "Images/Dewan/inkblocks_side_water.jpg"
    ],
    "moongate": [
        "Images/Dewan/moongate_blocked_far.jpg",
        "Images/Dewan/moongate_far_withib.jpg",
        "Images/Dewan/moongate_part1.jpg",
        "Images/Dewan/moongate_side.jpg",
        "Images/Dewan/moongate_side1.jpg",
        "Images/Dewan/moongate_whole.jpg",
        "Images/Dewan/moongate_whole1.jpg",
        "Images/Dewan/moongate_whole_far.jpg"
    ],
    "pavilion": [
        "Images/Dewan/pavilion.jpg",
        "Images/Dewan/pavilion_far.jpg",
        "Images/Dewan/pavilion_near.jpg",
        "Images/Dewan/pavilion_part.jpg",
        "Images/Dewan/pavilion_whole.jpg"
    ]
}

# Load reference images
reference_images = {
    label: [Image.open(p).convert("RGB") for p in paths]
    for label, paths in reference_paths.items()
}

# Text prompts
text_prompts = {
    "inkblocks": "square-shaped grey and black architectural feature",
    "moongate": "round shape like full moon, with red bricks and white paint bounded window",
    "pavilion": "round dome ceiling with square floors and red pillars, not only pillars"
}

# Encode reference images
reference_embeddings = {}
for label, images in reference_images.items():
    inputs = processor(images=images, return_tensors="pt", padding=True)
    with torch.no_grad():
        outputs = model.get_image_features(**inputs)
        outputs = outputs / outputs.norm(dim=-1, keepdim=True)
        reference_embeddings[label] = outputs

# Encode text prompts
text_embeddings = {}
for label, text in text_prompts.items():
    inputs = processor(text=[text], return_tensors="pt", padding=True)
    with torch.no_grad():
        outputs = model.get_text_features(**inputs)
        outputs = outputs / outputs.norm(dim=-1, keepdim=True)
        text_embeddings[label] = outputs

print("Model and references loaded.")

# API Endpoint for Prediction
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    print(f"Received file: {file.filename}")
    # Read uploaded image
    image_bytes = await file.read()
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")

    # Encode test image
    test_inputs = processor(images=img, return_tensors="pt")
    with torch.no_grad():
        test_embedding = model.get_image_features(**test_inputs)
        test_embedding = test_embedding / test_embedding.norm(dim=-1, keepdim=True)

    # Compare with reference images & text prompts
    similarities = {}
    for label in reference_embeddings:
        image_sims = F.cosine_similarity(test_embedding, reference_embeddings[label])
        image_sim = image_sims.max().item() 
        text_sim = F.cosine_similarity(test_embedding, text_embeddings[label]).item()
        combined_score = 0.6 * image_sim + 0.4 * text_sim
        similarities[label] = combined_score

    MATCH_THRESHOLD = 0.5

    # Get best match
    best_label = max(similarities, key=similarities.get)
    best_score = similarities[best_label]

    if best_score >= MATCH_THRESHOLD:
        predicted_label = best_label
    else:
        predicted_label = "unknown"


    # print prdicted result
    print(f"Predicted: {predicted_label}\n Similarities: {similarities}\n")

    return {
        "predicted": predicted_label,
        "similarities": similarities
    }
