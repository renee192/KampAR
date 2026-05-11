# 📍 KampAR

**Mobile Tour Guide Application with Real-Time Attraction Spot Recognition using VLM and AR for Kampar.**

![Project Status](https://img.shields.io/badge/Status-Complete-success)
![Platform](https://img.shields.io/badge/Platform-Android-blue)
![AI Models](https://img.shields.io/badge/Models-FastSAM%20%7C%20CLIP-orange)

## 📖 Overview
**KampAR** is a Final Year Project (FYP) designed to enhance the tourist experience in Kampar, a town located in Perak, Malaysia. By integrating pre-trained models, this mobile application acts as a real-time tour guide. 

Instead of using GPS, KampAR visually recognises specific "Attraction Spots" (distinct areas, statues, or items within a location) through the user's camera and overlays contextual, interactive labels right on the screen.

## ✨ Key Features
* **Real-Time Spot Recognition:** Captures a frame every 2 seconds and identifies specific micro-locations and landmarks in Kampar using the smartphone camera.
* **Information Overlays:** Displays labels directly over the recognised physical spot.
* **Intelligent Visual Pipeline:** Combines zero-shot object detection with powerful image classification to recognise spots without needing massive, heavily annotated local datasets.
* **Interactive Tour Guide:** Offers a seamless, self-guided tourist experience.

## 🔎 Supported Attraction Spots
| Location | Recognized Spot / Artifact |
| :--- | :--- |
| **🏛️ UTAR Grand Hall** | Moongate |
| | Ink Blocks |
| | Pavilion |
| **🛕 Seng Fatt Temple**| Bai Wu Chang (白无常) |
| | Chu Xun Pai Bian (出巡牌匾) |
| | Feng Xiang Zun Zhe (奉香尊者) |
| | Fu Lu Cai Shen Tu (福禄财神图) |
| | Guan Di Sheng Jun (关帝圣君) |
| | Guan Yin Pu Sa (观音菩萨) |
| | Mi Le Zun Zhe (弥勒尊者) |
| | Mu Lian Zun Zhe (目莲尊者) |
| | Qi Xian Xia Fan (七仙下凡) |
| | Shi Cai Zun Zhe (施财尊者) |

## 🧠 Recognition Pipeline
KampAR relies on a two-step pre-trained model pipeline to achieve high-accuracy, real-time recognition:

1. **Object Detection (FastSAM):** 
   Fast Segment Anything Model (FastSAM) is used to rapidly scan the real-time camera feed. It isolates and segments objects or structures in the frame, creating bounding boxes/masks around potential "Attraction Spots."
2. **Image Classification (CLIP - ViT-B/32):** 
   The segmented regions from FastSAM are passed to the CLIP - ViT-B/32 model, implemented via the Hugging Face `transformers` library. Specifically utilize the Vision Transformer (ViT) Base architecture with a 32x32 patch size. This variant was chosen because it offers an optimal balance between low-latency inference and high zero-shot classification accuracy, which is critical for providing a seamless, real-time AR experience for tourists.

## 🛠️ Technologies Used
* **Frontend / Mobile:** Flutter / Dart
* **AR Framework:** ARCore 
* **Pre-Trained Models:** 
  * [FastSAM](https://docs.ultralytics.com/models/fast-sam) (Fast Segment Anything)
  * [OpenAI CLIP (vit-base-patch32)](https://huggingface.co/openai/clip-vit-base-patch32) (Contrastive Language-Image Pretraining)
* **Backend / Cloud:** Python, FastAPI, Firebase, Google Cloud
---
🎥 **[Watch the demo here](https://drive.google.com/file/d/18Us5Hxz_G2mY96w0HGWW--QeMDsiBD4r/view?usp=drive_link)**
