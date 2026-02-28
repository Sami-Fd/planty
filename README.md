# 🌿 PlantDoctor

**AI-powered plant disease detection app** built with Flutter & TensorFlow Lite.

Point your camera at any plant leaf and get an instant diagnosis — no internet required.

[![Website](https://img.shields.io/badge/Website-sami--fd.github.io%2Fplanty-green?style=for-the-badge)](https://sami-fd.github.io/planty/)
[![Download APK](https://img.shields.io/badge/Download-APK-blue?style=for-the-badge&logo=android)](https://github.com/Sami-Fd/planty/releases/latest/download/app-release.apk)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](#license)

---

## ✨ Features

- **AI-Powered Detection** — MobileNetV2 model trained on thousands of plant images
- **38 Conditions** — Identifies diseases and healthy states across 14 plant species
- **100% Offline** — On-device inference with TensorFlow Lite, no internet needed
- **Camera & Gallery** — Capture a photo or pick from your gallery
- **Treatment Guidance** — Detailed disease info, treatment plans, irrigation & fertilization tips
- **Material 3 UI** — Modern design with light and dark mode support

## 📱 Screenshots

| Home                             | Scan                            | Results                               |
| -------------------------------- | ------------------------------- | ------------------------------------- |
| Welcome screen with instructions | Camera capture & gallery picker | Disease diagnosis with treatment info |

## 🌱 Supported Plants & Diseases

The model detects **38 conditions** across these plant species:

| Plant      | Diseases                                                                                                                                     |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Apple      | Scab, Black Rot, Cedar Rust, Healthy                                                                                                         |
| Cherry     | Powdery Mildew, Healthy                                                                                                                      |
| Corn       | Cercospora Leaf Spot, Common Rust, Northern Leaf Blight, Healthy                                                                             |
| Grape      | Black Rot, Esca, Leaf Blight, Healthy                                                                                                        |
| Orange     | Citrus Greening                                                                                                                              |
| Peach      | Bacterial Spot, Healthy                                                                                                                      |
| Pepper     | Bacterial Spot, Healthy                                                                                                                      |
| Potato     | Early Blight, Late Blight, Healthy                                                                                                           |
| Soybean    | Healthy                                                                                                                                      |
| Squash     | Powdery Mildew                                                                                                                               |
| Strawberry | Leaf Scorch, Healthy                                                                                                                         |
| Tomato     | Bacterial Spot, Early Blight, Late Blight, Leaf Mold, Septoria Leaf Spot, Spider Mites, Target Spot, Yellow Leaf Curl, Mosaic Virus, Healthy |

## 🏗️ Architecture

```
lib/
├── main.dart                  # App entry point & theme config
├── data/
│   └── disease_info_loader.dart   # JSON disease data loader
├── pages/
│   ├── splash_page.dart       # Splash screen
│   ├── home_page.dart         # Main hub with instructions
│   ├── camera_page.dart       # Camera capture & gallery
│   └── result_page.dart       # Diagnosis results & treatment
├── providers/
│   └── app_provider.dart      # Global state management
├── services/
│   └── model_service.dart     # TFLite inference engine
└── widgets/
    ├── buttons.dart           # Reusable button components
    ├── cards.dart             # Card widgets
    ├── loading_widgets.dart   # Loading indicators
    └── widgets.dart           # Shared UI components
```

**Key Technologies:**

- **Flutter** — Cross-platform UI framework
- **Provider** — State management
- **TensorFlow Lite** — On-device ML inference
- **MobileNetV2** — Lightweight image classification model

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.9+)
- Android SDK (for Android builds)

### Run Locally

```bash
# Clone the repo
git clone https://github.com/Sami-Fd/planty.git
cd planty

# Install dependencies
flutter pub get

# Run on a connected device
flutter run
```

### Build Release APK

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## 📥 Download

Get the latest APK from the [Releases page](https://github.com/Sami-Fd/planty/releases) or visit the [website](https://sami-fd.github.io/planty/).

## 🔗 Links

- **Website:** https://sami-fd.github.io/planty/
- **Releases:** https://github.com/Sami-Fd/planty/releases

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
