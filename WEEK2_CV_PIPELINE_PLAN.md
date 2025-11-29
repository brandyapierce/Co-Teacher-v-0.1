# Week 2 CV Pipeline - Step-by-Step Execution Plan

**Date**: November 2, 2025  
**Protocol**: MASTER - CV-INTEGRATION-001  
**Objective**: Implement complete CV pipeline for face detection and enrollment  
**Estimated Time**: 12-16 hours

---

## 🎯 Goals & Acceptance Criteria

### PoC Requirements:
- **Enrollment**: 3-5 poses per student
- **Detection**: ≥97% precision/recall
- **Speed**: Process classroom (20-25 students) in ≤120s
- **Privacy**: Local encrypted templates (no raw face uploads)
- **Temporal Smoothing**: Reduce false positives

---

## 📋 PHASE 1: Model Preparation (2-3 hours)

### Step 1.1: Research and Select CV Models
**Time**: 30 minutes  
**Tasks**:
- [ ] Research MediaPipe Face Detection models
- [ ] Research MediaPipe Face Mesh for landmarks
- [ ] Research FaceNet/MobileFaceNet for embeddings (ONNX)
- [ ] Document model choices and rationale

**Files to Create**:
- `docs/CV_MODEL_SELECTION.md`

---

### Step 1.2: Download MediaPipe Models
**Time**: 30 minutes  
**Tasks**:
- [ ] Download MediaPipe Face Detection model (.tflite)
- [ ] Download MediaPipe Face Mesh model (optional, for landmarks)
- [ ] Place in `apps/teacher_app/assets/models/`
- [ ] Verify file sizes and formats

**Expected Files**:
- `apps/teacher_app/assets/models/face_detection_short_range.tflite` (~1.3MB)
- `apps/teacher_app/assets/models/face_landmark.tflite` (optional)

**Resources**:
- MediaPipe Models: https://developers.google.com/mediapipe/solutions/vision/face_detector
- TFLite Models: https://storage.googleapis.com/mediapipe-models/face_detector/blaze_face_short_range/float16/latest/blaze_face_short_range.tflite

---

### Step 1.3: Download ONNX Face Recognition Model
**Time**: 45 minutes  
**Tasks**:
- [ ] Download MobileFaceNet ONNX model (~4MB)
- [ ] Alternative: FaceNet ONNX model
- [ ] Place in `apps/teacher_app/assets/models/`
- [ ] Test model format compatibility

**Expected Files**:
- `apps/teacher_app/assets/models/mobilefacenet.onnx`

**Resources**:
- ONNX Model Zoo: https://github.com/onnx/models
- MobileFaceNet: https://github.com/deepinsight/insightface/tree/master/model_zoo

---

### Step 1.4: Update Flutter Assets
**Time**: 15 minutes  
**Tasks**:
- [ ] Update `pubspec.yaml` with model paths
- [ ] Run `flutter pub get`
- [ ] Verify models are bundled (check build size)

**File**: `apps/teacher_app/pubspec.yaml`

---

## 📋 PHASE 2: Camera Pipeline (3-4 hours)

### Step 2.1: Implement Camera Service
**Time**: 1.5 hours  
**Tasks**:
- [ ] Create `CameraService` class
- [ ] Initialize camera with permissions
- [ ] Implement camera preview
- [ ] Implement image capture
- [ ] Handle camera lifecycle (pause/resume)

**Files**:
- `apps/teacher_app/lib/shared/data/services/camera_service.dart`

---

### Step 2.2: Create Camera Preview Widget
**Time**: 1 hour  
**Tasks**:
- [ ] Create `CameraPreviewWidget`
- [ ] Add overlay for face detection box
- [ ] Add capture button
- [ ] Handle camera errors gracefully

**Files**:
- `apps/teacher_app/lib/shared/presentation/widgets/camera_preview_widget.dart`

---

### Step 2.3: Implement Image Preprocessing
**Time**: 1 hour  
**Tasks**:
- [ ] Convert camera frame to format expected by models
- [ ] Resize images (160x160 for detection, 112x112 for embeddings)
- [ ] Normalize pixel values (0-1 or -1 to 1)
- [ ] Handle orientation/rotation

**Files**:
- `apps/teacher_app/lib/shared/utils/image_preprocessing.dart`

---

### Step 2.4: Test Camera Pipeline
**Time**: 30 minutes  
**Tasks**:
- [ ] Run app and open camera
- [ ] Verify preview displays
- [ ] Test capture functionality
- [ ] Check image preprocessing output

---

## 📋 PHASE 3: CV Service Integration (4-5 hours)

### Step 3.1: Integrate MediaPipe Face Detection
**Time**: 2 hours  
**Tasks**:
- [ ] Load MediaPipe TFLite model
- [ ] Implement `detectFaces(image)` method
- [ ] Parse model output (bounding boxes, confidence scores)
- [ ] Filter detections by confidence threshold (≥0.7)
- [ ] Draw bounding boxes on preview

**Files**:
- `apps/teacher_app/lib/shared/data/services/cv_service.dart` (update existing)

**Dependencies**:
- `tflite_flutter: ^0.10.4` (already in pubspec.yaml)

---

### Step 3.2: Integrate ONNX Face Recognition
**Time**: 2 hours  
**Tasks**:
- [ ] Add ONNX Runtime package
- [ ] Load ONNX model
- [ ] Implement `extractEmbedding(faceImage)` method
- [ ] Crop detected face from full image
- [ ] Generate 128D or 512D embedding vector
- [ ] Verify embedding quality

**Files**:
- `apps/teacher_app/lib/shared/data/services/cv_service.dart`

**Dependencies to Add**:
```yaml
onnxruntime: ^1.14.0  # Check latest version
```

---

### Step 3.3: Implement Face Matching
**Time**: 1 hour  
**Tasks**:
- [ ] Implement cosine similarity for embeddings
- [ ] Set matching threshold (≥0.75)
- [ ] Implement `matchStudent(embedding)` method
- [ ] Return top-k matches with confidence scores

**Files**:
- `apps/teacher_app/lib/shared/data/services/cv_service.dart`

---

### Step 3.4: Add Temporal Smoothing
**Time**: 30 minutes  
**Tasks**:
- [ ] Track detections across frames (sliding window)
- [ ] Average embeddings over N frames (N=3-5)
- [ ] Only return match if consistent across frames
- [ ] Reduce false positives

**Files**:
- `apps/teacher_app/lib/shared/data/services/cv_service.dart`

---

## 📋 PHASE 4: Face Enrollment UI (3-4 hours)

### Step 4.1: Create Enrollment Page
**Time**: 1.5 hours  
**Tasks**:
- [ ] Create `FaceEnrollmentPage` widget
- [ ] Add student selection dropdown/search
- [ ] Show camera preview
- [ ] Display pose instructions ("Look straight", "Turn left", etc.)
- [ ] Show captured poses (3-5 thumbnails)

**Files**:
- `apps/teacher_app/lib/features/enrollment/presentation/pages/face_enrollment_page.dart`

---

### Step 4.2: Implement Multi-Pose Capture
**Time**: 1.5 hours  
**Tasks**:
- [ ] Capture pose 1: Front face
- [ ] Capture pose 2: Left profile (~30°)
- [ ] Capture pose 3: Right profile (~30°)
- [ ] Optional: Pose 4-5: Slight variations
- [ ] Extract embeddings for all poses
- [ ] Average embeddings into single template

**Files**:
- `apps/teacher_app/lib/features/enrollment/presentation/pages/face_enrollment_page.dart`

---

### Step 4.3: Save Encrypted Templates
**Time**: 45 minutes  
**Tasks**:
- [ ] Encrypt embeddings using AES-256
- [ ] Store in Hive `face_templates` box
- [ ] Save with student ID, timestamp, pose count
- [ ] Never store raw images

**Files**:
- `apps/teacher_app/lib/shared/data/services/cv_service.dart` (encryption)

---

### Step 4.4: Add Enrollment List/Management
**Time**: 30 minutes  
**Tasks**:
- [ ] Create page to view enrolled students
- [ ] Show enrollment status (enrolled/pending)
- [ ] Allow re-enrollment
- [ ] Allow deletion of templates

**Files**:
- `apps/teacher_app/lib/features/enrollment/presentation/pages/enrollment_list_page.dart`

---

## 📋 PHASE 5: Testing & Validation (2-3 hours)

### Step 5.1: Unit Tests
**Time**: 1 hour  
**Tasks**:
- [ ] Test face detection with sample images
- [ ] Test embedding extraction
- [ ] Test cosine similarity calculation
- [ ] Test encryption/decryption

**Files**:
- `apps/teacher_app/test/services/cv_service_test.dart`

---

### Step 5.2: Integration Tests
**Time**: 1 hour  
**Tasks**:
- [ ] Test enrollment flow end-to-end
- [ ] Test face matching with enrolled templates
- [ ] Test with different lighting conditions
- [ ] Measure precision/recall

---

### Step 5.3: Performance Testing
**Time**: 1 hour  
**Tasks**:
- [ ] Measure detection time per frame
- [ ] Measure embedding extraction time
- [ ] Test with 20-25 enrolled students
- [ ] Verify meets ≤120s requirement

---

## 📋 PHASE 6: Backend Integration (Optional - 2 hours)

### Step 6.1: Update Backend CV Service
**Time**: 1 hour  
**Tasks**:
- [ ] Implement server-side face detection (OpenCV + ONNX)
- [ ] Add template storage in database
- [ ] Add matching endpoint

**Files**:
- `services/gateway_bff/app/services/cv_service.py`

---

### Step 6.2: Test API Endpoints
**Time**: 1 hour  
**Tasks**:
- [ ] Test `/api/v1/attendance/enroll` endpoint
- [ ] Test `/api/v1/attendance/scan` endpoint
- [ ] Verify privacy (no raw images stored)

---

## 📊 Success Criteria Checklist

### Functional Requirements
- [ ] Face detection working in real-time
- [ ] Face recognition (embedding + matching)
- [ ] Enrollment UI (3-5 poses per student)
- [ ] Encrypted local storage
- [ ] Temporal smoothing implemented

### Performance Requirements
- [ ] Detection accuracy: ≥97% precision/recall
- [ ] Speed: ≤120s for 20-25 students
- [ ] Frame rate: ≥10 FPS for camera preview

### Privacy Requirements
- [ ] No raw face images uploaded
- [ ] Templates encrypted locally
- [ ] Consent tracked in audit log

---

## 🛠️ Tools & Resources

### Flutter Packages
- `camera: ^0.10.5` ✅ Already added
- `tflite_flutter: ^0.10.4` ✅ Already added
- `onnxruntime: ^1.14.0` ⚠️ Need to add
- `image: ^4.0.0` ⚠️ Need to add (for preprocessing)

### Model Sources
- MediaPipe: https://developers.google.com/mediapipe
- ONNX Model Zoo: https://github.com/onnx/models
- InsightFace: https://github.com/deepinsight/insightface

### Documentation
- TFLite Flutter Guide: https://pub.dev/packages/tflite_flutter
- ONNX Runtime Flutter: https://pub.dev/packages/onnxruntime
- MediaPipe Face Detection: https://developers.google.com/mediapipe/solutions/vision/face_detector

---

## 📝 Next Steps After Completion

1. ✅ Commit and push all CV pipeline work
2. 📋 Begin Week 3: Attendance System
3. 📋 Build real-time attendance scanning page
4. 📋 Implement offline queue and sync

---

**Status**: Ready to Execute  
**Start Time**: TBD  
**Estimated Completion**: 12-16 hours of focused work









