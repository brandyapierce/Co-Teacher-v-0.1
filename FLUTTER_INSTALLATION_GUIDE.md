# 📱 Flutter Installation Guide - Windows

**Time Required**: 30-45 minutes  
**Difficulty**: Beginner-friendly  
**System**: Windows 10+

---

## 📋 Prerequisites

Before starting, ensure you have:
- ✅ Windows 10 or later (64-bit)
- ✅ At least 2.5 GB of free disk space
- ✅ Administrator access
- ✅ Internet connection

---

## 🚀 Step-by-Step Installation

### Step 1: Download Flutter SDK

**Option A: Direct Download (Recommended)**
1. Go to: https://docs.flutter.dev/get-started/install/windows
2. Click "Download Flutter SDK" (zip file, ~1.5-2GB)
3. Save to your Downloads folder

**Option B: Using Git (Alternative)**
```bash
git clone https://github.com/flutter/flutter.git -b stable
```

---

### Step 2: Extract Flutter SDK

1. **Navigate to Downloads folder**
2. **Right-click** the `flutter_windows_X.X.X-stable.zip` file
3. **Select** "Extract All..."
4. **Extract to**: `C:\flutter` (recommended location)
   - Or create a new folder: `C:\src\flutter`
   - **AVOID** folders with spaces or special characters

**Result**: You should have `C:\flutter\bin\flutter.bat`

---

### Step 3: Add Flutter to PATH

**Method 1: Using System Properties (Recommended)**

1. **Open System Properties**:
   - Press `Windows Key + R`
   - Type: `sysdm.cpl`
   - Press Enter

2. **Access Environment Variables**:
   - Click "Advanced" tab
   - Click "Environment Variables..." button

3. **Edit PATH**:
   - Under "User variables", find "Path"
   - Click "Edit..."
   - Click "New"
   - Add: `C:\flutter\bin` (or your Flutter location)
   - Click "OK" on all windows

**Method 2: Using PowerShell (Alternative)**

Open PowerShell as Administrator and run:
```powershell
[System.Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\flutter\bin', [System.EnvironmentVariableTarget]::User)
```

---

### Step 4: Verify Installation

1. **Close and reopen** your terminal/PowerShell
2. **Run**:
   ```bash
   flutter --version
   ```

**Expected Output**:
```
Flutter 3.X.X • channel stable
Framework • revision xxxxx
Engine • revision xxxxx
Tools • Dart 3.X.X
```

---

### Step 5: Run Flutter Doctor

This checks for missing dependencies:

```bash
flutter doctor
```

**Expected Output** (with issues to fix):
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.X.X)
[✗] Android toolchain - develop for Android devices
    ✗ Unable to locate Android SDK
[✗] Chrome - develop for the web
[✗] Visual Studio - develop for Windows
[!] Android Studio (not installed)
[✓] VS Code (version X.X.X)
[✓] Connected device (0 available)
```

**Don't worry about the ✗ marks yet!** We'll address them.

---

### Step 6: Install Visual Studio (for Windows development)

Flutter needs Visual Studio for Windows desktop apps:

1. **Download**: https://visualstudio.microsoft.com/downloads/
2. **Choose**: "Visual Studio 2022 Community" (free)
3. **During installation, select**:
   - ✅ Desktop development with C++
   - ✅ Windows 10 SDK or later

**Time**: 15-20 minutes

---

### Step 7: Accept Android Licenses (Optional)

If you want to build for Android:

```bash
flutter doctor --android-licenses
```

Press `y` to accept all licenses.

---

### Step 8: Verify Everything

Run Flutter Doctor again:

```bash
flutter doctor
```

**Goal**: Get as many ✓ checkmarks as possible.

---

## ✅ Quick Verification

Once installed, test with:

```bash
# Check Flutter version
flutter --version

# Check Dart version
dart --version

# Check for issues
flutter doctor
```

---

## 🎯 After Installation - Test Our App

Once Flutter is installed, run:

```bash
cd C:\Users\brand\Downloads\Co-Teacher-v-0.1\apps\teacher_app
flutter pub get
flutter analyze
```

---

## ⚠️ Common Issues

### Issue 1: "flutter not recognized"
**Solution**: PATH not set correctly
- Restart terminal
- Verify PATH includes `C:\flutter\bin`
- Reopen PowerShell as administrator

### Issue 2: "Android SDK not found"
**Solution**: Not needed for testing compilation
- You can ignore for now
- Only needed for running on Android devices

### Issue 3: "Visual Studio not found"
**Solution**: Install Visual Studio 2022 with C++ tools

---

## 📊 Installation Checklist

- [ ] Download Flutter SDK
- [ ] Extract to `C:\flutter`
- [ ] Add `C:\flutter\bin` to PATH
- [ ] Verify with `flutter --version`
- [ ] Run `flutter doctor`
- [ ] Install Visual Studio (optional)
- [ ] Test with our app: `flutter pub get`

---

## 🆘 Need Help?

If you encounter issues:
1. Close and reopen terminal
2. Run as Administrator
3. Check PATH is correct
4. Verify Flutter folder location

---

*Ready to proceed? Let me know when you've completed each step!*


