# ⚡ Flutter Installation - Quick Version

**For experienced users who want the essentials:**

---

## 1️⃣ Download & Extract
```bash
# Download from: https://docs.flutter.dev/get-started/install/windows
# Extract to: C:\flutter
```

## 2️⃣ Add to PATH
```powershell
# Run as Administrator
[System.Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\flutter\bin', [System.EnvironmentVariableTarget]::User)
```

Or manually:
- Win+R → `sysdm.cpl` → Advanced → Environment Variables
- Edit PATH → New → `C:\flutter\bin`

## 3️⃣ Verify
```bash
flutter --version
flutter doctor
```

## 4️⃣ Test Our App
```bash
cd C:\Users\brand\Downloads\Co-Teacher-v-0.1\apps\teacher_app
flutter pub get
flutter analyze
```

---

**That's it!** 🎉

See `FLUTTER_INSTALLATION_GUIDE.md` for detailed instructions.


