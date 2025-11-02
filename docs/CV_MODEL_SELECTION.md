# CV Model Selection for Co-Teacher PoC

**Date**: November 2, 2025  
**Phase**: Week 2 - Model Preparation  
**Decision Owner**: Technical Team

---

## 🎯 Requirements

### Functional Requirements:
- **Face Detection**: Real-time detection in classroom environment
- **Face Recognition**: Match detected faces to enrolled students
- **Enrollment**: Support 3-5 poses per student
- **Privacy**: On-device processing, encrypted storage

### Performance Requirements:
- **Accuracy**: ≥97% precision/recall
- **Speed**: Process 20-25 students in ≤120s
- **Frame Rate**: ≥10 FPS for camera preview
- **Model Size**: <15MB total (mobile constraints)

### Platform Requirements:
- **Flutter/Dart** compatibility
- **Windows Desktop** support (testing)
- **Android/iOS** support (deployment)
- **Offline operation** (no internet required)

---

## 🔍 Model Options Evaluated

### Face Detection Models

#### Option 1: MediaPipe BlazeFace (Short Range) ✅ **SELECTED**
- **Type**: TensorFlow Lite (.tflite)
- **Size**: ~1.3 MB
- **Input**: 128x128 RGB image
- **Output**: Face bounding boxes + 6 key points
- **Speed**: ~15ms on mobile CPU
- **Accuracy**: High for frontal faces (0-2m range)
- **Pros**:
  - Lightweight and optimized for mobile
  - Excellent performance on frontal faces
  - Well-documented and maintained by Google
  - Works with `tflite_flutter` package
- **Cons**:
  - Less accurate for profile views
  - Requires good lighting
- **Download**: https://storage.googleapis.com/mediapipe-models/face_detector/blaze_face_short_range/float16/latest/blaze_face_short_range.tflite

#### Option 2: MTCNN (Multi-task Cascaded CNN)
- **Size**: ~2 MB
- **Pros**: Better for varied angles
- **Cons**: Slower inference time
- **Status**: Considered but not selected (speed priority)

#### Option 3: YuNet (OpenCV)
- **Size**: ~320 KB
- **Pros**: Very lightweight
- **Cons**: Lower accuracy, less Flutter support
- **Status**: Not selected

---

### Face Recognition Models (Embedding Extraction)

#### Option 1: MediaPipe FaceMesh Embeddings ✅ **SELECTED (Phase 1)**
- **Type**: TensorFlow Lite (.tflite) - Already integrated
- **Size**: Included in MediaPipe package
- **Input**: Detected face region
- **Output**: 468 facial landmarks → can generate embedding
- **Speed**: ~20-30ms on mobile CPU
- **Accuracy**: Good for controlled environments
- **Pros**:
  - Already downloaded and configured
  - Zero additional setup required
  - Consistent with face detection pipeline
  - Pure TFLite architecture
- **Cons**:
  - Lower accuracy than dedicated embedding models
  - May need upgrade for production
- **Status**: Use for PoC, evaluate accuracy

#### Option 2: MobileFaceNet (TFLite Converted) 🔄 **FUTURE UPGRADE**
- **Type**: TensorFlow Lite (.tflite) - Requires conversion
- **Size**: ~4 MB
- **Input**: 112x112 RGB face crop
- **Output**: 128D embedding vector
- **Speed**: ~30-50ms on mobile CPU
- **Accuracy**: 99.5% on LFW benchmark
- **Pros**:
  - Optimized for mobile devices
  - High accuracy
  - Pure TFLite (no ONNX needed)
- **Cons**:
  - Requires ONNX → TFLite conversion
  - Additional model to manage
- **Conversion**: Use `tf2onnx` and TFLite converter
- **Status**: Phase 2 upgrade if needed

#### Option 2: FaceNet-Mobile
- **Size**: ~12 MB
- **Pros**: High accuracy (99.6% LFW)
- **Cons**: Larger size, slower
- **Status**: Considered but not selected (size constraint)

#### Option 3: ArcFace (ResNet50)
- **Size**: ~90 MB
- **Pros**: State-of-the-art accuracy
- **Cons**: Too large for mobile
- **Status**: Not suitable for mobile

---

## ✅ Final Selection - PURE TFLite ARCHITECTURE

### Selected Models:

1. **Face Detection**: MediaPipe BlazeFace (Short Range) ✅
   - File: `face_detection_short_range.tflite`
   - Size: 1.3 MB
   - Framework: TensorFlow Lite
   - Status: ✅ Downloaded and configured

2. **Face Landmarks**: MediaPipe Face Landmarker ✅
   - File: `face_landmarker.task`
   - Size: ~300KB
   - Framework: TensorFlow Lite
   - Status: ✅ Downloaded and configured

3. **Face Recognition (Phase 1)**: MediaPipe FaceMesh Embeddings ✅
   - File: Included in face_landmarker.task
   - Size: 0 MB (already included)
   - Framework: TensorFlow Lite
   - Status: ✅ Ready to use

4. **Face Recognition (Phase 2)**: MobileFaceNet TFLite (Future)
   - File: `mobilefacenet.tflite` (to be converted)
   - Size: ~4 MB
   - Framework: TensorFlow Lite
   - Status: 🔄 Optional upgrade if Phase 1 accuracy insufficient

**Current Model Size**: ~1.6 MB ✅ (Excellent!)  
**Projected Max Size**: ~5.6 MB with Phase 2 upgrade ✅ (Well under 15MB limit)

### 🎯 Architecture Decision: Pure TFLite
- **Single Runtime**: TensorFlow Lite only (no ONNX)
- **Benefits**: Smaller APK, simpler architecture, better Flutter support
- **Trade-off**: Must convert models to TFLite if needed
- **Status**: ✅ IMPLEMENTED

---

## 🔧 Integration Strategy - PURE TFLite

### TensorFlow Lite Integration (All CV Tasks) ✅
- **Package**: `tflite_flutter: ^0.10.4` ✅ (already in pubspec.yaml)
- **Runtime**: Single TFLite Interpreter for all models

### Face Detection Pipeline
- **Model**: `face_detection_short_range.tflite`
- **Preprocessing**: Resize to 128x128, normalize to [0,1]
- **Postprocessing**: Parse bounding boxes, filter by confidence ≥0.7
- **Status**: ✅ Ready for integration

### Face Landmark Detection Pipeline
- **Model**: `face_landmarker.task`
- **Preprocessing**: Crop face from detection bounding box
- **Postprocessing**: Extract 468 facial landmarks
- **Status**: ✅ Ready for integration

### Face Embedding Pipeline (Phase 1)
- **Model**: MediaPipe FaceMesh (included in face_landmarker.task)
- **Preprocessing**: Use detected face region
- **Feature Extraction**: Generate embedding from facial landmarks
- **Postprocessing**: L2 normalize embedding vector
- **Status**: ✅ Ready for implementation

### Face Embedding Pipeline (Phase 2 - Optional Upgrade)
- **Model**: MobileFaceNet (convert ONNX → TFLite)
- **Preprocessing**: Crop & resize to 112x112, normalize
- **Output**: 128D embedding vector
- **Postprocessing**: L2 normalize
- **Status**: 🔄 Available as accuracy upgrade if needed

---

## 🎨 Multi-Pose Enrollment Strategy

### Why Multi-Pose?
- Improves recognition across viewing angles
- Reduces false negatives in real-world conditions
- Captures face variations (expression, lighting)

### Recommended Poses:
1. **Pose 1**: Frontal face (looking straight at camera)
2. **Pose 2**: Left profile (~30° rotation)
3. **Pose 3**: Right profile (~30° rotation)
4. **Pose 4** (Optional): Slight smile
5. **Pose 5** (Optional): Different lighting

### Template Creation:
- Extract embedding for each pose
- **Option A**: Average all embeddings into single template
- **Option B**: Store all embeddings, match against closest one
- **Selected**: Option A (simpler, reduces storage)

---

## 🔐 Privacy & Security

### On-Device Processing:
- All detection and recognition happens locally
- No face images sent to server (unless explicit consent)
- Network only for metadata (student_id, timestamp, confidence)

### Encrypted Storage:
- Embeddings encrypted with AES-256
- Key derived from device secret + student ID
- Stored in Hive encrypted box

### Template Format:
```json
{
  "student_id": "12345",
  "embedding": [encrypted_128d_vector],
  "pose_count": 3,
  "enrolled_at": "2025-11-02T10:30:00Z",
  "version": "1.0"
}
```

---

## 📊 Expected Performance

### Detection Performance:
- **Frame Rate**: 15-20 FPS (66-40ms per frame)
- **Detection Latency**: ~15ms
- **False Positive Rate**: <5%

### Recognition Performance:
- **Embedding Extraction**: ~30-50ms per face
- **Matching**: ~1-2ms per template (cosine similarity)
- **Total per Student**: ~50-70ms

### Classroom Scenario (25 students):
- **Worst Case** (sequential): 25 × 70ms = 1.75s per frame
- **With optimization** (batch): <1s per frame
- **Total Scan Time**: 10-20 seconds ✅ (Well under 120s requirement)

---

## 🔄 Future Improvements

### Phase 2 Enhancements:
- Add face landmark detection for better alignment
- Implement face quality assessment (blur, occlusion)
- Add liveness detection (anti-spoofing)
- Support face mask detection

### Model Upgrades:
- Experiment with quantized INT8 models (faster)
- Test newer MediaPipe models
- Consider on-device training/fine-tuning

---

## 📚 References

### MediaPipe:
- Face Detection Guide: https://developers.google.com/mediapipe/solutions/vision/face_detector
- Models: https://developers.google.com/mediapipe/solutions/vision/face_detector/index#models

### MobileFaceNet:
- Paper: "MobileFaceNets: Efficient CNNs for Accurate Real-Time Face Verification on Mobile Devices"
- InsightFace Model Zoo: https://github.com/deepinsight/insightface/tree/master/model_zoo

### ONNX Runtime:
- Flutter Package: https://pub.dev/packages/onnxruntime
- Docs: https://onnxruntime.ai/docs/

---

## ✅ Decision Log

| Decision | Rationale | Date |
|----------|-----------|------|
| Use MediaPipe BlazeFace | Best balance of speed/accuracy for mobile | 2025-11-02 |
| **Pure TFLite Architecture** | **Simpler, smaller APK, better Flutter support** | **2025-11-02** |
| **Eliminate ONNX Runtime** | **Never implemented, TFLite sufficient** | **2025-11-02** |
| Use MediaPipe FaceMesh for embeddings (Phase 1) | Already integrated, zero additional setup | 2025-11-02 |
| Optional MobileFaceNet TFLite upgrade | Available if accuracy insufficient | 2025-11-02 |
| Multi-pose enrollment (3-5 poses) | Improve recognition across angles | 2025-11-02 |
| On-device processing | Privacy-first requirement | 2025-11-02 |
| AES-256 encryption for templates | Industry standard, sufficient security | 2025-11-02 |

---

**Status**: Model selection complete ✅  
**Next**: Download models and integrate


