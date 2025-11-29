# Android License Acceptance - Terminal Guide

## Step-by-Step Instructions

### 1. Open Your Terminal/PowerShell
(You should already have it open)

### 2. Run This Command:
```powershell
flutter doctor --android-licenses
```

### 3. What You'll See:
```
[=======================================] 100% Computing updates...
6 of 7 SDK package licenses not accepted.
Review licenses that have not been accepted (y/N)?
```

### 4. Type: y
Then press **Enter**

### 5. You'll See a License Agreement:
It will show something like:
```
---------------------------------------
Terms and Conditions
[Long license text...]
---------------------------------------
Accept? (y/N):
```

### 6. Type: y
Then press **Enter**

### 7. Repeat Steps 5-6:
You'll see this **6 more times** (total of 7 licenses)
- Just keep typing `y` and pressing Enter
- Each time it shows a license, type `y`

### 8. When Complete:
You'll see:
```
All SDK package licenses accepted.
```

### 9. Come Back Here and Type: "done"

---

## Quick Summary:
1. Run: `flutter doctor --android-licenses`
2. Type `y` and press Enter (7 times total)
3. Type "done" here when finished

That's it!





