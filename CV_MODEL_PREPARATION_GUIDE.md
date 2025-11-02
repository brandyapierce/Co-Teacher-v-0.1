# 📦 CV Model Preparation Guide

**Protocol**: PREPARATION-001  
**Status**: READY TO EXECUTE  
**Time Estimate**: 1 hour

---

## 🎯 Objective

Download and integrate MediaPipe face detection and ONNX Runtime Mobile embedding models for the Flutter app.

---

## 📋 Step-by-Step Guide

### Step 1: MediaPipe Face Detection Model

#### Option A: Use MediaPipe Flutter Plugin (Recommended)
**Package**: `google_mlkit_face_detection` or `mediapipe_flutter`

1. **Add to pubspec.yaml**:
   ```yaml
   dependencies:
     google_mlkit_face_detection: ^0.9.0
   ```

2. **No manual download needed** - package includes models

#### Option B: Manual Model Download
**URL**: https://github.com/google/mediapipe/tree/master/mediapipe/modules/face_detection

**Files to Download**:
- Face detection model files (.tflite)
- Place in: `apps/teacher_app/assets/models/mediapipe/`

---

### Step 2: ONNX Runtime Mobile Embedding Model

#### Model Selection
**Recommended**: ArcFace or MobileFaceNet (mobile-optimized)

**Sources**:
1. **ONNX Model Zoo**: https://github.com/onnx/models
   - Search for "face recognition" or "face embedding"
   
2. **Alternative**: Use pre-trained ArcFace model
   - Source: https://github.com/deepinsight/insightface
   - Convert to ONNX format if needed

#### Download Steps
1. Find mobile-optimized face embedding model
2. Download .onnx file
3. Place in: `apps/teacher_app/assets/models/onnx/face_embedding.onnx`

#### Model Requirements
- **Input Size**: 112x112 or 128x128
- **Output**: 512-dimensional embedding vector
- **Format**: ONNX (.onnx)
- **Size**: <10MB for mobile deployment

---

### Step 3: Update Flutter Assets

#### Update pubspec.yaml
```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
    - assets/models/
```

#### Create Directory Structure
```bash
apps/teacher_app/assets/
├── images/
├── icons/
└── models/
    ├── mediapipe/
    └── onnx/
        └── face_embedding.onnx
```

---

### Step 4: Integration in Flutter

#### MediaPipe Integration
```dart
// Example usage (Week 2 implementation)
import 'package:google_mlkit_face_detection/face_detection.dart';

final faceDetector = FaceDetector(
  options: FaceDetectorOptions(
    enableClassification: true,
    minFaceSize: 0.1,
  ),
);
```

#### ONNX Runtime Integration
```dart
// Example usage (Week 2 implementation)
import 'package:onnxruntime/onnxruntime.dart';

final ortEnv = OrtEnv();
final session = OrtSession.fromAsset('assets/models/onnx/face_embedding.onnx', ortEnv);
```

---

## 📊 Model Specifications

### MediaPipe Face Detection
- **Purpose**: Detect faces in images
- **Output**: Face bounding boxes and landmarks
- **Size**: ~1-2MB
- **Format**: TFLite (included in package)

### ONNX Face Embedding
- **Purpose**: Generate 512-dim face embeddings
- **Input**: 112x112 cropped face image
- **Output**: 512-dimensional vector
- **Size**: 5-10MB
- **Format**: ONNX

---

## ✅ Verification Checklist

- [ ] MediaPipe package added to pubspec.yaml
- [ ] ONNX Runtime package added to pubspec.yaml
- [ ] Model files downloaded (if manual)
- [ ] Models placed in assets/models/
- [ ] pubspec.yaml updated with assets
- [ ] Directory structure created
- [ ] Models loadable in Flutter (test in Week 2)

---

## 🔗 Resources

- **MediaPipe**: https://google.github.io/mediapipe/
- **ONNX Models**: https://github.com/onnx/models
- **ONNX Runtime Flutter**: https://pub.dev/packages/onnxruntime
- **ML Kit Face Detection**: https://pub.dev/packages/google_mlkit_face_detection

---

## ⏱️ Estimated Time

- Research: 15 minutes
- Download: 15 minutes
- Setup: 15 minutes
- Verification: 15 minutes
- **Total**: 1 hour

---

*Protocol: PREPARATION-001*  
*Status: READY*

