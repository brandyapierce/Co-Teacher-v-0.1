# Week 3: Attendance System - Implementation Plan

**Date**: November 6, 2025  
**Protocol**: MASTER - CV-INTEGRATION-001 → ATTENDANCE-SYSTEM-001  
**Objective**: Build real-time attendance scanning and offline sync system  
**Estimated Time**: 6-8 hours (can do in phases)

---

## 🎯 Week 3 Goals & Acceptance Criteria

### PoC Requirements:
- **Real-time scanning**: Teacher can scan classroom for attendance
- **Confidence-based UI**: Show match confidence, allow manual confirmation
- **Manual correction**: Teacher can correct misidentifications
- **Offline queue**: Store attendance records locally when offline
- **Background sync**: Auto-sync when connection available
- **Visual feedback**: Clear UI showing scan progress and results

---

## 📋 PHASE 1: Attendance Scanning Page (2-3 hours)

### Task 1.1: Create Attendance Scanning Page
**Time**: 1 hour  
**Location**: `apps/teacher_app/lib/features/attendance/presentation/pages/attendance_scan_page.dart`

**Features**:
- Camera preview in center
- Real-time face detection overlay
- Student name display when recognized
- Confidence score display
- Scan progress indicator
- Manual entry button

**UI Layout**:
```
┌─────────────────────────────────────┐
│  ← Back    Attendance Scan   ⚙️     │
├─────────────────────────────────────┤
│                                     │
│        [Camera Preview]             │
│        with face detection          │
│        boxes and names              │
│                                     │
├─────────────────────────────────────┤
│  📊 Scanned: 18/25 students        │
├─────────────────────────────────────┤
│  Recently Detected:                 │
│  ✓ Emma Johnson (95%)               │
│  ✓ Liam Williams (92%)              │
│  ? Olivia Brown (68%) [Confirm?]    │
├─────────────────────────────────────┤
│  [Manual Entry]  [View All]         │
└─────────────────────────────────────┘
```

---

### Task 1.2: Implement Scan State Management
**Time**: 45 minutes  
**Location**: `apps/teacher_app/lib/features/attendance/presentation/providers/attendance_scan_provider.dart`

**State**:
```dart
class AttendanceScanState {
  List<AttendanceRecord> scannedStudents;
  List<Student> pendingConfirmation;
  int totalStudents;
  bool isScanning;
  bool isOnline;
  int queuedRecords;
}
```

**Actions**:
- Start scan session
- Process face detection
- Confirm/reject identification
- Add manual attendance
- End scan session

---

### Task 1.3: Connect Camera and CV Service
**Time**: 45 minutes  

**Integration**:
- Use existing `CameraService` from Week 2
- Use existing `CVService` for face detection
- Process camera frames in real-time
- Match faces against enrolled templates
- Display results with confidence scores

---

## 📋 PHASE 2: Confidence-Based Confirmation UI (1.5-2 hours)

### Task 2.1: Create Confirmation Dialog
**Time**: 45 minutes  
**Location**: `apps/teacher_app/lib/features/attendance/presentation/widgets/confidence_confirmation_dialog.dart`

**Features**:
- Show detected face thumbnail
- Display matched student name
- Show confidence percentage
- Visual confidence indicator (color-coded)
- Accept/Reject buttons
- "Mark as present" option

**Confidence Levels**:
- **High (≥85%)**: Green, auto-accept after 2 seconds
- **Medium (70-84%)**: Yellow, require confirmation
- **Low (<70%)**: Red, require manual verification

---

### Task 2.2: Create Manual Entry Widget
**Time**: 45 minutes  
**Location**: `apps/teacher_app/lib/features/attendance/presentation/widgets/manual_attendance_entry.dart`

**Features**:
- Search students by name
- Alphabetical student list
- Quick filters (A-Z)
- Mark present/absent/tardy
- Add notes (optional)

---

## 📋 PHASE 3: Offline Queue & Sync (2-3 hours)

### Task 3.1: Implement Offline Queue with Hive
**Time**: 1.5 hours  
**Location**: `apps/teacher_app/lib/features/attendance/data/datasources/attendance_local_datasource.dart`

**Features**:
- Store attendance records locally when offline
- Queue with sync status
- Persist across app restarts
- Conflict resolution strategy

**Hive Box**:
```dart
@HiveType(typeId: 3)
class AttendanceQueueItem {
  @HiveField(0) String id;
  @HiveField(1) String studentId;
  @HiveField(2) String teacherId;
  @HiveField(3) DateTime timestamp;
  @HiveField(4) double confidence;
  @HiveField(5) bool synced;
  @HiveField(6) int retryCount;
}
```

---

### Task 3.2: Implement Background Sync Service
**Time**: 1 hour  
**Location**: `apps/teacher_app/lib/features/attendance/data/services/attendance_sync_service.dart`

**Features**:
- Detect network connectivity
- Auto-sync when online
- Retry failed syncs with exponential backoff
- Sync progress indicator
- Handle conflicts gracefully

**Sync Logic**:
1. Check network status
2. Get unsynced records from queue
3. Send to backend API
4. Mark as synced on success
5. Retry on failure (max 3 attempts)
6. Notify user of sync status

---

### Task 3.3: Add Sync Status UI
**Time**: 30 minutes  
**Location**: `apps/teacher_app/lib/features/attendance/presentation/widgets/sync_status_widget.dart`

**Features**:
- Online/offline indicator
- Pending sync count badge
- Manual sync button
- Last sync timestamp
- Sync progress bar

---

## 📋 PHASE 4: Attendance History & Review (1-2 hours)

### Task 4.1: Create Attendance List Page
**Time**: 1 hour  
**Location**: `apps/teacher_app/lib/features/attendance/presentation/pages/attendance_list_page.dart`

**Features**:
- List all attendance records
- Filter by date, class, status
- Search students
- Edit/delete records
- Export attendance report

---

### Task 4.2: Create Attendance Detail Page
**Time**: 45 minutes  

**Features**:
- Full attendance record details
- Student photo (if available)
- Timestamp and confidence
- Manual correction option
- Add notes
- Sync status

---

## 📋 PHASE 5: Testing & Polish (1 hour)

### Task 5.1: End-to-End Testing
**Time**: 30 minutes  

**Test Cases**:
- [ ] Start attendance scan session
- [ ] Detect face and match student (high confidence)
- [ ] Detect face with low confidence, confirm manually
- [ ] Add manual attendance entry
- [ ] Go offline, add attendance (queued)
- [ ] Go online, verify auto-sync
- [ ] View attendance history
- [ ] Edit attendance record

---

### Task 5.2: UI/UX Polish
**Time**: 30 minutes  

**Improvements**:
- Loading states
- Error messages
- Success animations
- Haptic feedback
- Smooth transitions
- Accessibility (screen readers, labels)

---

## 🛠️ Technical Architecture

### Data Flow:
```
Camera → CV Service → Face Detection → Template Matching
   ↓
Confidence Check → UI Confirmation → AttendanceRecord
   ↓
Local Storage (Hive) → Sync Queue → Backend API
   ↓
Success → Update UI → Remove from Queue
```

### State Management:
```
AttendanceScanProvider
  ├─ Camera state
  ├─ Detection results
  ├─ Pending confirmations
  └─ Scan statistics

AttendanceSyncProvider
  ├─ Network status
  ├─ Queue status
  ├─ Sync progress
  └─ Last sync time

AttendanceListProvider
  ├─ Attendance records
  ├─ Filters
  └─ Pagination
```

---

## 📊 Success Criteria Checklist

### Functional Requirements
- [ ] Real-time face detection working
- [ ] Confidence-based confirmation UI
- [ ] Manual entry available
- [ ] Offline queue functional
- [ ] Auto-sync when online
- [ ] Attendance history viewable
- [ ] Edit/correct capability

### Performance Requirements
- [ ] Scan frame rate: ≥10 FPS
- [ ] Detection latency: <500ms
- [ ] Sync latency: <2s per record
- [ ] Queue capacity: 1000+ records

### UX Requirements
- [ ] Clear scan progress feedback
- [ ] Intuitive confirmation flow
- [ ] Visual offline indicator
- [ ] Smooth transitions
- [ ] Error recovery

---

## 🎯 Week 3 File Structure

```
lib/features/attendance/
├── data/
│   ├── datasources/
│   │   ├── attendance_local_datasource.dart (Hive)
│   │   └── attendance_remote_datasource.dart (API)
│   ├── models/
│   │   ├── attendance_record_model.dart
│   │   └── attendance_queue_item.dart
│   ├── repositories/
│   │   └── attendance_repository_impl.dart
│   └── services/
│       └── attendance_sync_service.dart
├── domain/
│   ├── entities/
│   │   └── attendance_record.dart
│   └── repositories/
│       └── attendance_repository.dart
└── presentation/
    ├── pages/
    │   ├── attendance_scan_page.dart
    │   ├── attendance_list_page.dart
    │   └── attendance_detail_page.dart
    ├── providers/
    │   ├── attendance_scan_provider.dart
    │   ├── attendance_sync_provider.dart
    │   └── attendance_list_provider.dart
    └── widgets/
        ├── camera_scan_widget.dart
        ├── confidence_confirmation_dialog.dart
        ├── manual_attendance_entry.dart
        ├── sync_status_widget.dart
        └── attendance_card.dart
```

---

## 📝 Implementation Strategy

### Approach: Incremental Build & Test

**Session 1** (2 hours):
- Phase 1: Attendance scanning page with basic UI
- Test: Can see camera and scan button works

**Session 2** (2 hours):
- Phase 2: Confidence confirmation UI
- Test: Can confirm/reject detections

**Session 3** (2 hours):
- Phase 3: Offline queue and sync
- Test: Records saved offline, sync when online

**Session 4** (1 hour):
- Phase 4: Attendance history
- Phase 5: Testing and polish

---

## 🔗 Dependencies

### Existing (Already in Project):
- ✅ `camera` - Camera access
- ✅ `tflite_flutter` - Face detection
- ✅ `hive` - Local storage
- ✅ `get_it` - Dependency injection
- ✅ `go_router` - Navigation
- ✅ `riverpod` - State management

### May Need to Add:
- `connectivity_plus` - Network status detection
- `flutter_local_notifications` - Sync notifications (optional)

---

## 🎯 Ready to Start?

**Next Step**: Begin Phase 1 - Attendance Scanning Page

We'll build incrementally, testing each component as we go!

---

**Protocol**: MASTER  
**Sub-Protocol**: ATTENDANCE-SYSTEM-001  
**Status**: Ready to Execute  
**Estimated Completion**: 6-8 hours across multiple sessions





