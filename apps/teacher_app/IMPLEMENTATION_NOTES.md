# Implementation Notes - Co-Teacher Teacher App

## TFLite on Windows Issue

**Problem**: The `tflite_flutter` package (v0.10.4) has a compilation error on Windows:
```
error: The method 'UnmodifiableUint8ListView' isn't defined for the type 'Tensor'
```

**Solution**: 
- TFLite is temporarily disabled in `pubspec.yaml` for Windows development
- Created `CVServiceMock` to allow UI testing without TFLite
- The real TFLite implementation (`CVServiceEnhanced`) is ready and will work on Android/iOS

**To Enable TFLite on Mobile:**
1. Uncomment in `pubspec.yaml`:
   ```yaml
   tflite_flutter: ^0.10.4
   ```

2. Update imports in:
   - `lib/features/enrollment/presentation/pages/face_enrollment_page.dart`
   - `lib/features/enrollment/presentation/pages/enrollment_list_page.dart`
   - `lib/core/di/injection_container.dart`
   
   Change:
   ```dart
   import '../../../../shared/data/services/cv_service_mock.dart';
   final CVServiceMock _cvService = CVServiceMock();
   ```
   
   To:
   ```dart
   import '../../../../shared/data/services/cv_service_enhanced.dart';
   final CVServiceEnhanced _cvService = CVServiceEnhanced();
   ```

3. Test on a physical Android or iOS device

## CV Pipeline Architecture

### Current (Phase 1 - Windows Testing):
- **Camera**: Real camera service
- **Face Detection**: Mock (random results)
- **Embeddings**: Mock (random 128D vectors)
- **Storage**: Real (Hive with encryption)
- **UI**: Fully functional

### Future (Phase 2 - Mobile Production):
- **Camera**: Real camera service ✅
- **Face Detection**: TFLite MediaPipe BlazeFace
- **Embeddings**: TFLite Face landmarks → embedding
- **Storage**: Real (Hive with AES-256) 
- **UI**: Fully functional ✅

## File Structure

```
lib/
├── core/
│   ├── di/
│   │   └── injection_container.dart        # DI setup
│   ├── router/
│   │   └── app_router.dart                 # Routes including enrollment
│   └── ...
├── features/
│   ├── enrollment/
│   │   └── presentation/
│   │       └── pages/
│   │           ├── face_enrollment_page.dart      # Multi-pose capture
│   │           └── enrollment_list_page.dart      # Student management
│   └── ...
└── shared/
    ├── data/
    │   └── services/
    │       ├── camera_service.dart                # Camera operations
    │       ├── cv_service.dart                    # Original placeholder
    │       ├── cv_service_enhanced.dart           # TFLite (for mobile)
    │       └── cv_service_mock.dart               # Mock (for Windows)
    ├── presentation/
    │   └── widgets/
    │       └── camera_preview_widget.dart         # Camera UI + overlays
    └── utils/
        └── image_preprocessing.dart               # CV utilities
```

## Key Components

### CameraService
- Manages camera lifecycle
- Supports multiple cameras (front/back)
- Captures images as Uint8List
- Handles permissions

### CVServiceEnhanced (TFLite - Mobile)
- Loads face_detection_short_range.tflite
- Detects faces with confidence scores
- Extracts embeddings (Phase 1: simple, Phase 2: MobileFaceNet)
- Matches faces using cosine similarity
- Stores encrypted templates

### CVServiceMock (Windows Testing)
- Simulates face detection (80% success rate)
- Generates random embeddings
- Same API as CVServiceEnhanced
- Allows full UI testing

### FaceEnrollmentPage
- Multi-pose capture (3-5 poses)
- Real-time feedback
- Progress indicators
- Error handling
- Beautiful completion screen

## Testing Strategy

### Windows Development:
1. Use mock service to develop and test UI
2. Verify enrollment flow
3. Test error handling
4. Polish UX

### Android/iOS Testing:
1. Enable TFLite
2. Test on physical device
3. Benchmark performance
4. Tune confidence thresholds
5. Test in various conditions

## Performance Targets

- **Face Detection**: ~15ms per frame
- **Embedding Extraction**: ~30-50ms per face
- **Total Enrollment**: <30 seconds for 5 poses
- **Attendance Scan**: 20-25 students in ≤120 seconds

## Known Limitations

1. **Windows**: TFLite not working (mock service only)
2. **Phase 1 Embeddings**: Simple feature extraction (not production-quality)
3. **Encryption**: Currently XOR-based (upgrade to AES-256 for production)
4. **Temporal Smoothing**: Not yet implemented (planned for Phase 2)

## Future Improvements

1. Add temporal smoothing (average detections across frames)
2. Upgrade to AES-256 encryption
3. Add MobileFaceNet TFLite model for better embeddings
4. Add face quality assessment (blur detection, occlusion)
5. Add liveness detection
6. Support face masks

## Dependencies

Current:
```yaml
camera: ^0.10.5+5
permission_handler: ^11.0.1
image: ^4.0.0
hive: ^2.2.3
crypto: ^3.0.3
# tflite_flutter: ^0.10.4  # Disabled for Windows
```

For Mobile:
```yaml
tflite_flutter: ^0.10.4  # Uncomment for Android/iOS
```

## Build & Run

### Windows (Current):
```bash
flutter pub get
flutter build windows --debug
flutter run -d windows
```

### Android (Future):
```bash
# 1. Uncomment tflite_flutter in pubspec.yaml
# 2. Switch to CVServiceEnhanced in code
flutter pub get
flutter build apk --debug
flutter run -d <android-device>
```

---

*Last Updated: November 2, 2025*

