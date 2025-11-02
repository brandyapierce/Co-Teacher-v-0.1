# Co-Teacher PoC Task List (Weeks 1-6)

## Week 1: Foundation & Core Infrastructure ✅ COMPLETE

### Backend Foundation
- [x] Mono-repo scaffold
- [x] FastAPI gateway_bff with all routers
- [x] Database models for all entities
- [x] Alembic migrations setup
- [x] Docker Compose configuration
- [x] JWT authentication
- [x] OneRoster importer
- [x] Sample data (25 students, 3 teachers)

## Week 2: Computer Vision Pipeline 🎯 CURRENT FOCUS

### Backend CV Service
- [ ] CV service with face detection and embedding extraction
  - Files: `services/gateway_bff/app/services/cv_service.py`
- [ ] Face template storage and matching with cosine similarity
- [ ] Temporal smoothing for false positive reduction
- [ ] Confidence scoring with configurable thresholds

### Mobile CV Service
- [ ] MediaPipe TFLite face detection integration
  - Files: `apps/teacher_app/lib/shared/data/services/cv_service.dart`
- [ ] TFLite face embeddings (MediaPipe FaceMesh)
- [ ] Local encrypted face template storage with Hive
- [ ] Camera pipeline with preview and capture
- [ ] Face enrollment UI (3-5 poses per student)
- **Architecture**: Pure TFLite (no ONNX) ✅

## Week 3: Attendance System

### Attendance Scanning
- [ ] Real-time attendance scanning page
- [ ] Face detection and matching UI
- [ ] Confidence-based confirmation UI
- [ ] Manual correction flow
- [ ] Offline queue with Hive
- [ ] Background sync logic

## Immediate Fixes Required 🔨

### Flutter App Issues (4-6 hours)
1. **DI Container** - Remove non-existent module references
   - File: `apps/teacher_app/lib/core/di/injection_container.dart`
2. **Router** - Fix import paths and create missing pages
   - File: `apps/teacher_app/lib/core/router/app_router.dart`
3. **Auth Pages** - Create login and splash screens
   - Files: `apps/teacher_app/lib/features/auth/presentation/pages/`
4. **Hive Boxes** - Fix initialization
   - File: `apps/teacher_app/lib/core/di/injection_container.dart`

### CV Models
- [x] Download MediaPipe face detection model ✅ (face_detection_short_range.tflite)
- [x] Download MediaPipe face landmarker ✅ (face_landmarker.task)
- [x] Add to Flutter assets ✅ (assets/models/)
- [x] Update pubspec.yaml ✅
- [x] TFLite package integrated ✅ (tflite_flutter: ^0.10.4)
- **Status**: ✅ READY FOR INTEGRATION (Pure TFLite architecture)

