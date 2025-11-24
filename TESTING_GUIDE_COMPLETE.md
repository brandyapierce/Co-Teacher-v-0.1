# 🧪 Co-Teacher Testing Guide - Complete Walkthrough

**Date**: November 18, 2025  
**Version**: Week 3 Complete (80% Overall Progress)  
**Testing Duration**: 30-45 minutes  
**Status**: Ready for Testing

---

## 📋 Table of Contents

1. [Pre-Testing Setup](#pre-testing-setup)
2. [Backend Testing](#backend-testing)
3. [Flutter App Testing](#flutter-app-testing)
4. [Feature Testing Checklist](#feature-testing-checklist)
5. [Known Limitations](#known-limitations)
6. [Troubleshooting](#troubleshooting)

---

## 🚀 Pre-Testing Setup

### Prerequisites Checklist

- [x] Docker Desktop installed
- [x] Flutter SDK v3.35.7 installed
- [x] Project downloaded at: `C:\Users\brand\Downloads\Co-Teacher-v-0.1`
- [x] Docker Desktop is starting (3-5 min initialization time)

### Step 1: Verify Docker is Running

```powershell
# Wait 3-5 minutes after running restart_docker.ps1
docker ps
```

**Expected Output**: Should show running containers (or empty table if none running yet)

**If Error**: Docker Desktop not fully initialized - wait 2 more minutes and retry

### Step 2: Start Backend Services

```powershell
# From project root: C:\Users\brand\Downloads\Co-Teacher-v-0.1
docker-compose up -d
```

**Expected Output**:
```
Creating coteacher-postgres ... done
Creating coteacher-redis    ... done
Creating coteacher-gateway  ... done
```

**Wait Time**: ~2-3 minutes for first build (if images don't exist)

### Step 3: Verify Backend Health

```powershell
# Check containers are running
docker ps

# Test health endpoint
curl http://localhost:8000/health
```

**Expected Output**:
```json
{"status":"healthy","version":"1.0.0"}
```

---

## 🔧 Backend Testing

### Test 1: API Documentation

**Action**: Open browser to http://localhost:8000/docs

**Expected**: Interactive Swagger UI with 7 API sections:
- ✅ Authentication
- ✅ Attendance
- ✅ Rotations
- ✅ Evidence
- ✅ Insights
- ✅ Messaging
- ✅ Consent & Audit

**Screenshot**: You should see a clean FastAPI interface with all endpoints listed

---

### Test 2: Authentication Flow

**Action**: In Swagger UI, test the login endpoint

**Steps**:
1. Click on `/api/v1/auth/login` → "Try it out"
2. Use demo credentials:
   ```json
   {
     "email": "teacher1@school.edu",
     "password": "password123"
   }
   ```
3. Click "Execute"

**Expected Output**:
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

**Status Code**: 200 OK

**If 401 Unauthorized**: Sample data not imported - see [Import Sample Data](#import-sample-data)

---

### Test 3: Get Current User Info

**Action**: Test the `/api/v1/auth/me` endpoint

**Steps**:
1. Copy the `access_token` from Test 2
2. Click the "Authorize" button (top-right of Swagger UI)
3. Paste token in format: `Bearer <your_token>`
4. Click "Authorize" → "Close"
5. Navigate to `/api/v1/auth/me` → "Try it out" → "Execute"

**Expected Output**:
```json
{
  "id": "teacher-id-123",
  "email": "teacher1@school.edu",
  "name": "Jane Smith",
  "role": "teacher"
}
```

---

### Test 4: Get Students List

**Action**: Test the `/api/v1/attendance/students` endpoint

**Steps**:
1. Ensure you're authorized (from Test 3)
2. Navigate to `/api/v1/attendance/students`
3. Try it out → Execute

**Expected Output**: List of 25 students with:
```json
[
  {
    "id": "student-1",
    "first_name": "Emma",
    "last_name": "Johnson",
    "grade": "3",
    "class_name": "Class 3A"
  },
  ...
]
```

---

### Import Sample Data (If Needed)

If authentication fails because sample data doesn't exist:

```powershell
cd services\gateway_bff
python import_sample_data.py
```

**Expected Output**:
```
Imported 3 teachers successfully.
Imported 25 students successfully.
Done!
```

---

## 📱 Flutter App Testing

### Test 5: Launch Flutter App

**Action**: Start the Flutter app on Windows Desktop

```powershell
# From project root
cd apps\teacher_app
flutter run -d windows
```

**Wait Time**: 2-5 minutes for first build

**Expected Output**: App window opens showing login screen

**Build Success Indicator**:
```
✓ Built build\windows\x64\runner\Release\teacher_app.exe
Launching lib\main.dart on Windows in debug mode...
```

---

### Test 6: Authentication Screen

**What to Test**: Login UI and validation

**Actions**:
1. **Verify UI Elements**:
   - [x] Email input field
   - [x] Password input field
   - [x] "Remember Me" checkbox
   - [x] "Login" button
   - [x] "Forgot Password?" link

2. **Test Empty Validation**:
   - Click "Login" with empty fields
   - **Expected**: Red error text appears "Please enter your email"

3. **Test Invalid Email**:
   - Enter: `notanemail`
   - Enter password: `test123`
   - Click "Login"
   - **Expected**: Error text "Please enter a valid email"

4. **Test Successful Login** (Mock - no backend connection yet):
   - Enter: `teacher1@school.edu`
   - Enter: `password123`
   - Click "Login"
   - **Expected**: Progress indicator shows, then navigates to home screen

**Screenshot**: Clean, modern login screen with purple/blue gradient

---

### Test 7: Home Dashboard

**What to Test**: Main navigation and dashboard

**Actions**:
1. **Verify UI Elements**:
   - [x] Top app bar with "My AI CoTeacher"
   - [x] Teacher name/avatar (if logged in)
   - [x] Navigation drawer/menu
   - [x] Main content area

2. **Test Navigation Items**:
   - Click "Attendance" → Should navigate to attendance scan page
   - Click "Students" → Should navigate to students list
   - Click "Classes" → Should navigate to classes (if implemented)

**Expected**: Smooth animations, no crashes

---

### Test 8: Attendance Scanning Page

**What to Test**: Core attendance functionality

**Actions**:

#### 8.1 Camera Preview (Mock)
- Navigate to "Attendance" → "Scan Attendance"
- **Expected**: 
  - Camera preview area (or mock preview if no camera)
  - "Scanning..." status indicator
  - Progress counter "0/25 students marked"

#### 8.2 Network Status Widget
- Look for sync status in top-right
- **Expected**: 
  - 🔴 "Offline" (if backend not connected)
  - "0 pending" queue counter
  - Sync button

#### 8.3 Manual Attendance Entry
- Click "Manual Entry" button (bottom-right FAB)
- **Expected**:
  - Dialog opens with student list
  - Search bar at top
  - A-Z filter chips
  - Student cards with avatars

**Test Manual Entry**:
1. Type "Emma" in search → Should filter to Emma Johnson
2. Click "A" filter chip → Should show only students with names starting with A
3. Select a student → Dialog closes
4. **Expected**: Confirmation appears at bottom

#### 8.4 Status Selection
- In manual entry, click a student
- **Expected**: 
  - Status buttons: "Present" | "Absent" | "Tardy"
  - Optional notes field
  - "Mark Attendance" button

**Test Status**:
1. Select "Present" → Button highlights green
2. Select "Tardy" → Button highlights orange
3. Add note: "Arrived at 8:15 AM"
4. Click "Mark Attendance"
5. **Expected**: Success snackbar, progress counter updates "1/25"

---

### Test 9: Face Detection (Mock Mode)

**What to Test**: Confidence-based confirmation

**Simulation**: Since we're on desktop without mobile camera:

**Actions**:
1. In attendance scan page, the system would trigger face detection
2. For testing purposes, you'll see mock detection results

**What SHOULD Happen** (when implemented on mobile):
- Camera detects face
- Shows confidence dialog with:
  - Student photo/avatar
  - Name: "Emma Johnson"
  - Confidence: 92% (High) - Green indicator
  - "Accept" and "Reject" buttons

**Confidence Levels**:
- 🟢 **High (≥85%)**: "High confidence - likely correct"
- 🟠 **Medium (70-84%)**: "Medium confidence - please verify"
- 🔴 **Low (<70%)**: "Low confidence - manual review needed"

**Test Actions**:
- Click "Accept" → Marks attendance
- Click "Reject" → Opens manual entry dialog

---

### Test 10: Offline Queue System

**What to Test**: Offline functionality and sync

**Actions**:

#### 10.1 Verify Offline Mode
- Ensure backend is NOT connected (or stop Docker)
- Mark attendance for 3 students manually
- **Expected**: 
  - Success messages appear
  - Sync status shows "🔴 Offline - 3 pending"

#### 10.2 Queue Counter
- Check top-right status widget
- **Expected**: "3 pending" counter updates in real-time

#### 10.3 Manual Sync (When Backend Returns)
- Start backend: `docker-compose up -d`
- Wait ~10 seconds for connectivity
- **Expected**:
  - Status changes to "🟢 Online"
  - Auto-sync begins
  - Progress bar appears
  - Counter decreases: "2 pending" → "1 pending" → "0 pending"
  - Success message: "✅ All records synced"

#### 10.4 Sync Status Details
- Click on sync status widget
- **Expected**: Expanded panel shows:
  - Connectivity status
  - Last sync time
  - Items in queue
  - Sync progress bar
  - Manual "Sync Now" button

---

### Test 11: Attendance History

**What to Test**: View and manage past attendance records

**Actions**:

#### 11.1 Navigate to History
- Click "Attendance" → "View History" (or menu item)
- **Expected**: 
  - List of all attendance records
  - Cards showing student name, status, date/time
  - Filter options at top

#### 11.2 Filters
- **Date Filter**: Click calendar icon
  - Select "Today" → Shows only today's records
  - Select "This Week" → Shows week's records
  - Select custom date range
  
- **Status Filter**: Click status dropdown
  - Select "Present" → Shows only present
  - Select "Absent" → Shows only absent
  - Select "Tardy" → Shows only tardy
  - Select "All" → Shows everything

- **Class Filter**: Click class dropdown
  - Select "Class 3A" → Filters to that class
  - Select "All Classes" → Shows all

#### 11.3 Search
- Type "Emma" in search bar
- **Expected**: Real-time filtering to Emma Johnson's records

#### 11.4 Record Details
- Click on an attendance card
- **Expected**: Detail view shows:
  - Student photo/avatar
  - Full name and grade
  - Attendance status with color
  - Date and time
  - Notes (if any)
  - Confidence score (if CV-based)
  - "Edit" and "Delete" buttons

#### 11.5 Edit Record
- Click "Edit" on a record
- Change status from "Present" to "Tardy"
- Add note: "Corrected from Present"
- Click "Save"
- **Expected**: 
  - Record updates
  - Success snackbar
  - Returns to list
  - Changes visible immediately

#### 11.6 Delete Record
- Click "Delete" on a record
- **Expected**: 
  - Confirmation dialog appears
  - "Are you sure?" message
  - "Cancel" and "Delete" buttons
- Click "Delete"
- **Expected**: 
  - Record removed from list
  - Success message
  - Counter updates

---

### Test 12: Student List

**What to Test**: View enrolled students

**Actions**:
1. Navigate to "Students" from menu
2. **Expected**:
   - List of all students (demo data: 25 students)
   - Student cards with:
     - Avatar (initials)
     - Name
     - Grade
     - Class
   - Search bar at top

3. **Test Search**:
   - Type "Johnson" → Filters to Johnson students
   - Clear search → All students return

4. **Test Student Details** (if implemented):
   - Click on a student card
   - **Expected**: Detail page with student info

---

### Test 13: Face Enrollment (Desktop Mock)

**What to Test**: Enrollment flow (UI only on desktop)

**Actions**:
1. Navigate to "Enrollment" from menu
2. Select a student from list
3. **Expected**: Enrollment screen with:
   - Camera preview (mock on desktop)
   - Instructions: "Capture 3-5 poses"
   - Progress: "0/5 poses captured"
   - "Capture" button

**Mock Capture**:
- Click "Capture" button 5 times
- **Expected**:
  - Progress updates: 1/5, 2/5, 3/5, 4/5, 5/5
  - Visual feedback (checkmarks or thumbnails)
  - When complete: "Enrollment Complete" message
  - "Save" button appears

**Save Enrollment**:
- Click "Save"
- **Expected**:
  - Processing indicator
  - Success message
  - Encrypted data stored locally (Hive)
  - Returns to student list

---

## ✅ Feature Testing Checklist

### Backend (All tests via Swagger UI)

- [ ] **Authentication Service**
  - [ ] Login with valid credentials → 200 OK with JWT
  - [ ] Login with invalid credentials → 401 Unauthorized
  - [ ] Get current user info `/me` → Returns user data
  - [ ] Token expiry (30 minutes)

- [ ] **Attendance Service**
  - [ ] Get students list → Returns 25 students
  - [ ] Scan attendance (mock) → Accepts request
  - [ ] Query attendance by date → Returns records

- [ ] **Rotations Service**
  - [ ] Create rotation → 201 Created
  - [ ] Get rotations → Returns list
  - [ ] Update rotation → 200 OK
  - [ ] Delete rotation → 204 No Content

- [ ] **Insights Service**
  - [ ] Get analytics data → Returns metrics
  - [ ] Generate reports → Success

- [ ] **Consent & Audit Service**
  - [ ] Create consent record → 201 Created
  - [ ] Get audit logs → Returns logs
  - [ ] Privacy compliance checks

### Flutter App (All tests in running app)

- [ ] **Authentication**
  - [ ] Login screen displays correctly
  - [ ] Form validation works
  - [ ] Login success navigates to home
  - [ ] Login error shows message
  - [ ] Remember me checkbox

- [ ] **Attendance Scanning**
  - [ ] Scan page loads with camera preview (mock)
  - [ ] Progress counter displays (0/25)
  - [ ] Network status widget shows
  - [ ] Manual entry dialog opens
  - [ ] Student search works
  - [ ] A-Z filters work
  - [ ] Status selection (Present/Absent/Tardy)
  - [ ] Notes field accepts input
  - [ ] Mark attendance succeeds
  - [ ] Success feedback appears
  - [ ] Counter updates

- [ ] **Confidence Confirmation** (Mock)
  - [ ] Dialog displays with student info
  - [ ] Confidence level shows with color
  - [ ] Accept button works
  - [ ] Reject button works

- [ ] **Offline Queue**
  - [ ] Queue counter displays
  - [ ] Records queue when offline
  - [ ] Status indicator shows offline/online
  - [ ] Auto-sync when connection restored
  - [ ] Manual sync button works
  - [ ] Sync progress shows
  - [ ] Success/error messages display

- [ ] **Attendance History**
  - [ ] History page loads
  - [ ] Records display in list
  - [ ] Date filter works
  - [ ] Status filter works
  - [ ] Class filter works
  - [ ] Search works
  - [ ] Click record opens details
  - [ ] Edit record works
  - [ ] Delete record works (with confirmation)
  - [ ] Changes persist

- [ ] **Student Management**
  - [ ] Students list loads
  - [ ] Search filters students
  - [ ] Student cards display correctly
  - [ ] Click student shows details (if implemented)

- [ ] **Face Enrollment**
  - [ ] Enrollment page loads
  - [ ] Camera preview shows (mock)
  - [ ] Capture progress tracks (0/5 → 5/5)
  - [ ] Save enrollment succeeds
  - [ ] Data encrypted and stored
  - [ ] Success feedback

- [ ] **UI/UX**
  - [ ] App theme applied (purple/blue)
  - [ ] Animations smooth
  - [ ] No crashes or freezes
  - [ ] Responsive to window resize
  - [ ] Icons display correctly
  - [ ] Error messages clear
  - [ ] Loading indicators show
  - [ ] Navigation works

---

## ⚠️ Known Limitations

### Desktop Testing Limitations

1. **No Real Camera**: 
   - Desktop testing uses mock camera preview
   - Face detection won't actually work until tested on mobile
   - Enrollment captures are simulated

2. **GPS Not Available**:
   - Location services not available on Windows desktop
   - GPS features need mobile device testing

3. **Backend Connection**:
   - App is currently in "mock mode" for most operations
   - Real backend integration is Week 4 task
   - Authentication flows to backend, but attendance data is local-only

### Feature Status

#### ✅ Fully Implemented & Testable
- Authentication UI (frontend only)
- Attendance scanning page (UI complete)
- Manual attendance entry
- Confidence confirmation dialog (mock data)
- Offline queue system
- Sync status widgets
- Attendance history (CRUD operations)
- Student list with search
- Face enrollment UI (mock capture)
- Local storage (Hive)

#### 🟡 Partially Implemented
- Backend API (5/7 services operational)
- Face detection (TFLite models ready, mobile testing needed)
- JWT authentication (backend works, app integration pending)

#### ⏳ Not Yet Implemented
- Real camera integration on mobile
- Live face detection/recognition
- Backend sync (Week 4 task)
- GPS location verification
- Evidence upload service
- Messaging service
- Reports & analytics dashboard

---

## 🐛 Troubleshooting

### Issue: Docker won't start

**Symptoms**: `error during connect` when running `docker ps`

**Solution**:
```powershell
.\restart_docker.ps1
# Wait 5 minutes, then retry
docker ps
```

**If still failing**: 
- Check Docker Desktop in system tray
- Open Docker Desktop manually
- Check WSL2 status: `wsl --status`

---

### Issue: `docker-compose up` fails

**Symptoms**: Container build errors or ports in use

**Solution 1 - Ports in use**:
```powershell
# Stop all containers
docker-compose down

# Check what's using port 8000
netstat -ano | findstr :8000

# Kill process (replace PID)
taskkill /PID <PID> /F

# Restart
docker-compose up -d
```

**Solution 2 - Image issues**:
```powershell
# Rebuild from scratch
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

---

### Issue: Backend API returns 500 errors

**Symptoms**: Endpoints return "Internal Server Error"

**Check Logs**:
```powershell
docker logs coteacher-gateway
```

**Common Causes**:
1. Database not initialized:
   ```powershell
   cd services\gateway_bff
   alembic upgrade head
   ```

2. Sample data missing:
   ```powershell
   python import_sample_data.py
   ```

3. Environment variables not set:
   - Check `services/gateway_bff/.env` exists
   - Copy from `services/gateway_bff/env.example`

---

### Issue: Flutter app won't build

**Symptoms**: Build errors or dependencies missing

**Solution**:
```powershell
cd apps\teacher_app

# Clean build
flutter clean
flutter pub get

# Check Flutter doctor
flutter doctor -v

# Rebuild
flutter run -d windows
```

**If dependencies fail**:
```powershell
# Update Flutter
flutter upgrade

# Re-fetch packages
rm pubspec.lock
flutter pub get
```

---

### Issue: App crashes on launch

**Symptoms**: Window opens then immediately closes

**Check Console**:
- Look for error messages in terminal
- Common issues:
  - Missing assets: Check `pubspec.yaml` assets section
  - DI container errors: Check `lib/core/di/injection.dart`
  - Route errors: Check `lib/core/router/router.dart`

**Debug Mode**:
```powershell
flutter run -d windows --verbose
```

---

### Issue: Hive storage errors

**Symptoms**: "Box not found" or encryption errors

**Solution**:
```powershell
# Clear Hive storage (resets local data)
# On Windows, delete:
# C:\Users\<username>\AppData\Roaming\teacher_app\
```

---

### Issue: Attendance records not saving

**Symptoms**: Mark attendance but records disappear

**Check**:
1. Hive boxes initialized? (Check console logs)
2. Offline queue working? (Check sync status widget)
3. Backend connection? (Check network status)

**Debug**:
- Look for errors in Flutter console
- Check if records are in queue: "X pending"
- Try manual sync

---

### Issue: Face detection not working

**Expected**: Desktop testing won't have real face detection

**To Test Properly**:
- Need Android/iOS device
- Connect via USB
- Run: `flutter run -d <device_id>`
- Use physical device camera
- This is Week 2 completion task (deferred)

---

## 📊 Testing Results Template

Use this template to document your testing session:

```markdown
# Testing Session Results

**Date**: [Date]
**Tester**: [Your Name]
**Duration**: [Time spent]
**Environment**: Windows 10/11 Desktop

## Backend Tests
- [ ] Docker starts successfully
- [ ] Containers running: Postgres, Redis, Gateway
- [ ] API health check passes
- [ ] Swagger UI accessible
- [ ] Authentication works
- [ ] Students list returns data

**Notes**: [Any issues or observations]

## Flutter App Tests
- [ ] App builds successfully
- [ ] Login screen displays
- [ ] Navigation works
- [ ] Attendance scan page loads
- [ ] Manual entry works
- [ ] Offline queue functional
- [ ] Attendance history works
- [ ] Search and filters work

**Notes**: [Any issues or observations]

## Issues Found
1. [Issue description]
   - Severity: Critical / High / Medium / Low
   - Steps to reproduce:
   - Expected vs Actual:

## Overall Assessment
- **Build Quality**: Excellent / Good / Fair / Poor
- **UI/UX**: Excellent / Good / Fair / Poor
- **Performance**: Fast / Acceptable / Slow
- **Stability**: Stable / Minor Issues / Unstable

## Recommendations
- [Suggested improvements]
```

---

## 🎯 Next Steps After Testing

### If All Tests Pass ✅
**Recommended**: Proceed to Week 4 - Backend Integration
- Connect app to real backend API
- Implement JWT authentication flow
- Sync attendance records to database
- Real-time student roster updates

### If Issues Found 🐛
**Action**: Document issues in testing template above
- Critical issues: Fix before proceeding
- Minor issues: Add to backlog
- UI improvements: Note for polish phase

### Optional: Mobile Testing
**If Device Available**: Complete Week 2 mobile testing
- Test real camera integration
- Test face detection on device
- Verify GPS location
- Complete Week 2 to 100%

---

## 📞 Support

### Documentation References
- **Master Protocol**: `MASTER_PROTOCOL_SESSION.md`
- **Task Log**: `TASK_LOG_CURRENT.md`
- **API Docs**: http://localhost:8000/docs (when backend running)
- **Backend Setup**: `DOCKER_INSTALLATION_VERIFICATION.md`
- **Flutter Setup**: `FLUTTER_INSTALLATION_GUIDE.md`

### Quick Commands Reference

```powershell
# Backend
docker-compose up -d              # Start all services
docker-compose down               # Stop all services
docker logs coteacher-gateway     # View backend logs
docker ps                         # Check running containers

# Flutter
cd apps\teacher_app
flutter run -d windows            # Launch app
flutter clean                     # Clean build
flutter doctor                    # Check environment
```

---

**Testing Protocol Ready** ✅  
**Duration**: 30-45 minutes for complete walkthrough  
**Last Updated**: November 18, 2025

*Happy Testing! 🎉*

