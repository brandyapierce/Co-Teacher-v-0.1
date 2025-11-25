# 🔗 Week 4: Backend Integration Plan

**Start Date**: November 24, 2025  
**Estimated Duration**: 3-4 hours  
**Status**: 🚀 ACTIVE  
**Priority**: HIGH - Critical Path

---

## 🎯 Objectives

**Primary Goal**: Connect Flutter app to backend API for full end-to-end functionality

**Success Criteria**:
- ✅ Students load from backend database (25 students)
- ✅ Attendance records sync to backend
- ✅ Real-time data updates
- ✅ Offline queue syncs when online
- ✅ Network error handling
- ✅ JWT authentication in app

---

## 📊 Current State

### **What's Working** ✅
- Backend API (7 services, 40+ endpoints)
- Flutter app UI (all features built)
- Local storage (Hive)
- Offline queue system
- Authentication flow (frontend)

### **What's Missing** ⏳
- API service layer in Flutter
- Backend data fetch
- Attendance sync to backend
- Network error handling
- Real JWT integration

---

## 🔨 Implementation Phases

### **Phase 1: API Service Layer** (1 hour)

**Objective**: Create service layer to communicate with backend

**Tasks**:
1. ✅ Create `StudentApiService` class
2. ✅ Create `AttendanceApiService` class
3. ✅ Update `ApiClient` with new endpoints
4. ✅ Add error handling and retry logic
5. ✅ Integration with existing services

**Files to Create**:
- `lib/features/students/data/services/student_api_service.dart`
- `lib/features/attendance/data/services/attendance_api_service.dart`

**Files to Modify**:
- `lib/core/network/api_client.dart`
- `lib/core/di/injection.dart`

---

### **Phase 2: Student List Integration** (45 minutes)

**Objective**: Load students from backend database

**Tasks**:
1. ✅ Update `StudentsCubit` to fetch from API
2. ✅ Add loading/error states
3. ✅ Handle empty state
4. ✅ Cache students locally
5. ✅ Pull-to-refresh functionality

**Current State**:
```dart
// Shows empty state
"No Students found. Add students to get started."
```

**Target State**:
```dart
// Shows 25 students from backend
Emma Johnson, Liam Williams, Olivia Brown...
```

**Files to Modify**:
- `lib/features/students/presentation/providers/students_cubit.dart`
- `lib/features/students/presentation/pages/students_page.dart`

---

### **Phase 3: Attendance Sync** (1 hour)

**Objective**: Sync attendance records to backend

**Tasks**:
1. ✅ Create attendance POST endpoint integration
2. ✅ Update `AttendanceScanCubit` to sync records
3. ✅ Modify offline queue to use real API
4. ✅ Handle sync conflicts
5. ✅ Update sync status in real-time

**Current Behavior**:
- Records saved only to Hive (local)
- Queue shows "5 pending"
- No backend sync

**Target Behavior**:
- Records saved to Hive AND backend
- Queue syncs to backend when online
- Success confirmation from backend

**Files to Modify**:
- `lib/core/services/offline_queue_service.dart`
- `lib/features/attendance/presentation/providers/attendance_scan_cubit.dart`

---

### **Phase 4: Network Error Handling** (30 minutes)

**Objective**: Gracefully handle network issues

**Tasks**:
1. ✅ Connection timeout handling
2. ✅ Server error handling (500, 503)
3. ✅ Auth errors (401, 403)
4. ✅ Retry with exponential backoff
5. ✅ User-friendly error messages

**Scenarios to Handle**:
- No internet connection
- Backend server down
- Invalid/expired token
- Rate limiting
- Partial data sync

**Files to Modify**:
- `lib/core/services/auth_service.dart` (already has error handling)
- `lib/core/network/api_client.dart`
- New: `lib/core/network/network_error_handler.dart`

---

### **Phase 5: Testing & Verification** (30 minutes)

**Objective**: Validate end-to-end functionality

**Test Scenarios**:
1. ✅ Students load from backend on app launch
2. ✅ Mark attendance → syncs to backend immediately
3. ✅ Go offline → mark attendance → comes online → auto-sync
4. ✅ Edit attendance record → updates backend
5. ✅ Delete attendance record → deletes from backend
6. ✅ Backend down → queue stores locally
7. ✅ Invalid token → re-authentication flow

**Verification**:
- Check backend database (PostgreSQL)
- Check Swagger API responses
- Check app behavior
- Check error handling

---

## 🔧 Technical Implementation Details

### **API Endpoints to Integrate**

**Students**:
```
GET /api/v1/attendance/students
→ Returns: List of 25 students
```

**Attendance**:
```
POST /api/v1/attendance/scan
→ Body: { student_id, status, timestamp, notes }
→ Returns: Created attendance record

GET /api/v1/attendance/records
→ Query params: date, class_id, status
→ Returns: List of attendance records

PUT /api/v1/attendance/records/{id}
→ Body: { status, notes }
→ Returns: Updated record

DELETE /api/v1/attendance/records/{id}
→ Returns: Success message
```

---

### **Authentication Flow**

**Current**: JWT stored after login  
**Need to Add**: Include JWT in all API requests

```dart
// Add to ApiClient
final token = await _tokenStorage.getAccessToken();
if (token != null) {
  options.headers['Authorization'] = 'Bearer $token';
}
```

---

### **Data Flow Architecture**

**Before Week 4**:
```
User Action → Cubit → Local Storage (Hive)
                    ↓
                 UI Updates
```

**After Week 4**:
```
User Action → Cubit → API Service → Backend
                    ↓              ↓
              Local Storage    PostgreSQL
                    ↓              ↓
                 UI Updates ← Response
```

---

### **Offline Queue Enhancement**

**Current Logic**:
```dart
1. User marks attendance
2. Save to Hive
3. Add to queue
4. Queue shows "X pending"
5. Manual sync does nothing (no backend)
```

**New Logic**:
```dart
1. User marks attendance
2. Save to Hive (immediate feedback)
3. Try sync to backend
   → Success: Mark as synced, remove from queue
   → Failure: Keep in queue, retry later
4. Queue shows "X pending"
5. Auto-retry with exponential backoff
6. Manual sync triggers immediate retry
```

---

## 📝 Code Patterns

### **Pattern 1: API Service**

```dart
class StudentApiService {
  final ApiClient _apiClient;
  
  StudentApiService(this._apiClient);
  
  Future<List<Student>> getStudents() async {
    try {
      final response = await _apiClient.get('/api/v1/attendance/students');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Student.fromJson(json)).toList();
      }
      
      throw ApiException('Failed to load students');
    } catch (e) {
      rethrow;
    }
  }
}
```

---

### **Pattern 2: Cubit with API Integration**

```dart
class StudentsCubit extends Cubit<StudentsState> {
  final StudentApiService _apiService;
  
  StudentsCubit(this._apiService) : super(StudentsInitial());
  
  Future<void> loadStudents() async {
    emit(StudentsLoading());
    
    try {
      final students = await _apiService.getStudents();
      emit(StudentsLoaded(students));
    } catch (e) {
      emit(StudentsError(e.toString()));
    }
  }
}
```

---

### **Pattern 3: Offline-First Strategy**

```dart
Future<void> markAttendance(Student student, AttendanceStatus status) async {
  // 1. Save locally first (immediate feedback)
  await _localStorage.saveAttendance(record);
  emit(AttendanceMarked(record));
  
  // 2. Try to sync to backend
  try {
    await _apiService.createAttendance(record);
    // Success - mark as synced
    await _localStorage.markAsSynced(record.id);
  } catch (e) {
    // Failure - add to queue for later
    await _offlineQueue.add(record);
    emit(AttendanceQueued(record));
  }
}
```

---

## 🧪 Testing Strategy

### **Unit Tests**
- API service methods
- Error handling
- Data parsing
- State management

### **Integration Tests**
- End-to-end flows
- Network error scenarios
- Offline/online transitions
- Data synchronization

### **Manual Tests**
1. Fresh app start → students load
2. Mark attendance → verify in backend
3. Offline mode → mark → online → auto-sync
4. Backend down → graceful degradation
5. Token expiry → re-auth flow

---

## 📊 Success Metrics

### **Functionality**
- [ ] Students load from backend (200 OK)
- [ ] Attendance syncs to backend (201 Created)
- [ ] Edit/delete syncs to backend
- [ ] Offline queue works with backend
- [ ] Error handling graceful

### **Performance**
- [ ] Student list loads < 1 second
- [ ] Attendance sync < 500ms
- [ ] No UI blocking during API calls
- [ ] Background sync efficient

### **User Experience**
- [ ] Loading states clear
- [ ] Error messages helpful
- [ ] Offline mode transparent
- [ ] Sync progress visible

---

## 🚧 Known Challenges

### **Challenge 1: Network Reliability**
**Issue**: Mobile networks can be unreliable  
**Solution**: Offline-first architecture with queue

### **Challenge 2: Token Management**
**Issue**: JWT tokens expire (30 min)  
**Solution**: Refresh token before expiry, handle 401 errors

### **Challenge 3: Data Conflicts**
**Issue**: Local data may differ from backend  
**Solution**: Server is source of truth, sync conflicts handled

### **Challenge 4: Performance**
**Issue**: Loading 25+ students may be slow  
**Solution**: Pagination, caching, optimistic updates

---

## 📋 Checklist

### **Phase 1: API Service Layer**
- [ ] Create StudentApiService
- [ ] Create AttendanceApiService
- [ ] Update ApiClient with endpoints
- [ ] Add to DI container
- [ ] Test with Postman/Swagger

### **Phase 2: Student List**
- [ ] Integrate API service in StudentsCubit
- [ ] Add loading/error states
- [ ] Update UI for loading
- [ ] Test student list loads
- [ ] Verify 25 students appear

### **Phase 3: Attendance Sync**
- [ ] Update mark attendance to call API
- [ ] Modify offline queue to use API
- [ ] Implement auto-sync
- [ ] Test sync on reconnect
- [ ] Verify backend database updates

### **Phase 4: Error Handling**
- [ ] Handle network errors
- [ ] Handle auth errors
- [ ] User-friendly messages
- [ ] Retry logic
- [ ] Test error scenarios

### **Phase 5: Testing**
- [ ] End-to-end flow test
- [ ] Offline mode test
- [ ] Error handling test
- [ ] Performance test
- [ ] User acceptance test

---

## 🎯 Definition of Done

**Week 4 is complete when**:
1. ✅ Students load from backend database
2. ✅ Attendance records sync to backend
3. ✅ Offline queue syncs when online
4. ✅ All CRUD operations hit backend
5. ✅ Network errors handled gracefully
6. ✅ Zero critical bugs
7. ✅ Testing completed
8. ✅ Documentation updated
9. ✅ Code pushed to GitHub

---

## 🚀 Next Steps After Week 4

### **Week 5: Class Management** (Optional)
- Create/edit classes
- Assign students to classes
- Teacher-class relationships
- Schedule management

### **Week 6: Reports & Analytics** (Optional)
- Attendance reports
- Analytics dashboard
- Export to CSV/PDF
- Data visualization

### **Week 7: Production Deployment** (Final)
- Environment configuration
- Security hardening
- Performance optimization
- User training
- Go live!

---

## 📚 Resources

### **API Documentation**
- Swagger UI: http://localhost:8000/docs
- Backend repo: Already on GitHub
- API contract: See Swagger schemas

### **Flutter Packages**
- dio: ^5.3.3 (already installed)
- connectivity_plus: ^5.0.1 (already installed)
- hive: ^2.2.3 (already installed)

### **References**
- TESTING_REPORT_FINAL.md (test results)
- MASTER_PROTOCOL_STATUS.md (project status)
- Backend API endpoints (verified via testing)

---

**Plan Created**: November 24, 2025  
**Status**: Ready to Execute  
**Estimated Completion**: 3-4 hours  
**Next Action**: Begin Phase 1 - API Service Layer

---

*Let's connect the frontend to the backend and complete the MVP!* 🚀

