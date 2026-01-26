# Running Co-Teacher App on Your Local Machine

This guide walks you through running the Flutter app on your local machine with Android emulator.

---

## **Prerequisites**

### **1. Install Android Studio**
- Download from [developer.android.com/studio](https://developer.android.com/studio)
- Follow platform-specific installation instructions
- Complete initial setup

### **2. Install Flutter**
```bash
git clone https://github.com/flutter/flutter.git
export PATH="$PATH:~/flutter/bin"
flutter doctor  # Verify installation
```

### **3. Clone Co-Teacher Repository**
```bash
git clone https://github.com/brandyapierce/Co-Teacher-v-0.1.git
cd Co-Teacher-v-0.1/apps/teacher_app
```

---

## **Setup Android Emulator (One-Time)**

### **Using Android Studio GUI** (Easiest)

1. **Open Android Studio** → **Tools** → **Device Manager**
2. **Click "Create Device"**
3. **Select Phone → Pixel 4** (recommended)
4. **Choose API 34 or 35** (latest stable)
5. **Select x86_64** system image (fastest)
6. **Click Finish**

### **Using Command Line**
```bash
# List available devices
avdmanager list device

# Create AVD
avdmanager create avd -n "Pixel4API34" \
  -k "system-images;android-34;default;x86_64" \
  -d "Pixel 4" -c 2048M
```

---

## **Run the App**

### **Option A: Auto-Launch Emulator**
```bash
flutter run
```
Flutter will automatically:
1. Start the emulator
2. Build the app
3. Install it on emulator
4. Launch it

### **Option B: Manual Emulator Control**

**Start emulator manually:**
```bash
flutter emulators --launch Pixel4API34  # Or your AVD name
```

**In another terminal, run the app:**
```bash
flutter run -d emulator-5554
```

### **Option C: Run on Physical Device**

**Enable USB debugging on phone:**
1. Settings → Developer options (enable if hidden)
2. Check "USB debugging"
3. Connect phone via USB

**Run app:**
```bash
flutter devices  # Should see your phone
flutter run
```

---

## **Testing the App**

### **Multi-Pose Face Enrollment**
1. Tap "Start Enrollment"
2. Capture 3 poses:
   - Front facing
   - 45° left
   - 45° right
3. See enrollment success screen
4. Use mock CV service (80% accuracy simulation)

### **View Enrolled Students**
1. Tap "Enrolled Students"
2. See list from local storage (Hive)
3. Swipe to delete students

### **Test Backend API**
```bash
# Start backend (in separate terminal)
cd services/gateway_bff
python main.py

# Visit Swagger UI
open http://localhost:8000/docs
```

---

## **Build for Production**

### **Generate APK** (for sharing/testing)
```bash
flutter build apk --split-per-abi
# Output: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### **Generate App Bundle** (for Play Store)
```bash
flutter build appbundle
# Output: build/app/outputs/bundle/release/app-release.aab
```

### **Install APK on Device/Emulator**
```bash
flutter install  # Uses currently running device/emulator
```

---

## **Troubleshooting**

| Issue | Solution |
|-------|----------|
| `Flutter not found` | Add Flutter to PATH: `export PATH="$PATH:~/flutter/bin"` |
| `Android SDK not found` | Run `flutter doctor` and follow suggestions |
| `Emulator won't start` | Enable virtualization in BIOS (VT-x / AMD-V) |
| `Device not detected` | Try `flutter doctor -v` to diagnose |
| `App crashes on launch` | Check logcat: `adb logcat \| grep ERROR` |
| `Slow emulator` | Use x86_64 (not ARM), allocate 4GB RAM, disable animations |

---

## **Development Workflow**

### **Hot Reload** (Fast iteration)
```bash
flutter run
# Make code changes, then press 'r' in terminal to hot reload
```

### **Hot Restart** (Full app restart)
```bash
# While app is running, press 'R' in terminal
```

### **Full Rebuild**
```bash
flutter clean
flutter run
```

---

## **Project Structure**

```
apps/teacher_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/
│   │   └── theme/                   # Material 3 design
│   ├── features/
│   │   └── enrollment/
│   │       └── presentation/pages/  # UI pages
│   └── shared/
│       └── data/services/           # CV service interface
├── pubspec.yaml                     # Dependencies
└── README.md                        # More info
```

---

## **Key Features Ready to Test**

| Feature | Status | Location |
|---------|--------|----------|
| Face Enrollment (Multi-pose) | ✅ Ready | `features/enrollment/presentation/pages/` |
| Student List Management | ✅ Ready | `features/enrollment/presentation/pages/` |
| Local Storage (Hive) | ✅ Ready | Cache layer, offline-first |
| CV Service Interface | ✅ Ready | `shared/data/services/cv_service.dart` |
| Backend API Integration | ✅ Ready | Ready for real MediaPipe when needed |

---

## **Backend Testing**

### **Start Backend Server**
```bash
cd services/gateway_bff
python main.py
```

### **Test Enrollment Endpoint**
```bash
curl -X POST http://localhost:8000/v1/enroll \
  -H "Content-Type: multipart/form-data" \
  -F "student_id=student123" \
  -F "student_name=John Doe" \
  -F "class_id=class1" \
  -F "face_images=@face1.jpg" \
  -F "face_images=@face2.jpg" \
  -F "face_images=@face3.jpg"
```

### **Get Enrollment Status**
```bash
curl http://localhost:8000/v1/enroll/status/student123
```

### **List Enrolled Students**
```bash
curl http://localhost:8000/v1/enroll/list/class1
```

See [TESTING_GUIDE.md](../../TESTING_GUIDE.md) for complete API testing guide.

---

## **Performance Tips**

- Use **Release mode** for final testing: `flutter run --release`
- Use **x86_64 system image** for faster emulation
- **Allocate 4GB RAM** to emulator in Android Studio settings
- Disable emulator animations for speed
- On Mac M1/M2: Use ARM-based system image instead of x86_64

---

## **Support & Next Steps**

1. ✅ **App compiles** - 0 errors
2. ✅ **Backend ready** - All endpoints implemented  
3. ✅ **Database ready** - Schema prepared
4. 🔄 **Testing phase** - You're here!
5. 📦 **Deploy to Play Store** - Follow DEVELOPMENT_STATUS.md

**Questions?** Check the repo documentation in `/docs` folder.

Good luck! 🚀
