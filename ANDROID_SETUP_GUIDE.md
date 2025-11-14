# 📱 Android Device Setup for Flutter Development

**Quick Setup Guide** - Follow these steps to connect your Android device

---

## Step 1: Enable Developer Options

1. **Open Settings** on your Android device
2. **Go to**: Settings → About Phone (or About Device)
3. **Find**: "Build Number" (might be under "Software Information")
4. **Tap "Build Number" 7 times** rapidly
5. **You'll see**: "You are now a developer!" message

✅ Developer Options is now enabled!

---

## Step 2: Enable USB Debugging

1. **Go back to Settings**
2. **Find**: "Developer Options" (usually in System or Advanced settings)
3. **Turn on**: "Developer Options" toggle at the top
4. **Scroll down and enable**: "USB Debugging"
5. **Confirm**: Tap "OK" on the warning dialog

✅ USB Debugging is now enabled!

---

## Step 3: Connect to Computer

1. **Connect** your Android device to computer via USB cable
2. **On your phone**: You'll see a popup "Allow USB debugging?"
3. **Check**: "Always allow from this computer" (optional but recommended)
4. **Tap**: "Allow" or "OK"

✅ Device is now connected and authorized!

---

## Step 4: Verify Connection

Once connected, I'll run `flutter devices` to verify Flutter can see your device.

Your device should appear in the list!

---

## Troubleshooting

### Device not showing up?
- Try a different USB cable (some cables are charge-only)
- Make sure USB Debugging is enabled
- Try "Revoke USB debugging authorizations" in Developer Options, then reconnect
- Check if Windows recognizes the device (Device Manager)

### Need USB drivers?
- Most modern Android devices work automatically
- If needed, install manufacturer's USB drivers
- Or install Google USB Driver from Android Studio

---

**Ready?** Follow Steps 1-3, then let me know when your device is connected!

