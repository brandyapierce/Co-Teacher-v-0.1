import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import '../../../../core/network/app_exception.dart';
import '../models/attendance_record.dart';
import '../services/attendance_api_service.dart';

/// Repository for managing attendance data
/// 
/// EDUCATIONAL NOTE - Repository Pattern:
/// The repository abstracts WHERE the data comes from (API, local storage, etc.)
/// from the business logic (Cubit). This provides:
/// 
/// 1. **Single Source of Truth**: All attendance data flows through here
/// 2. **Offline-First Strategy**: Try local cache first, then API
/// 3. **Sync Management**: Handle syncing local changes to backend
/// 4. **Testability**: Easy to mock for testing
/// 
/// Architecture:
/// Cubit → Repository → [ApiClient, Hive] ← Repository → Cubit
class AttendanceRepository {
  final AttendanceApiService _apiService = GetIt.instance<AttendanceApiService>();
  final Box _attendanceBox = GetIt.instance<Box>(instanceName: 'attendance_records');

  /// Get all attendance records with optional filters
  /// 
  /// Strategy:
  /// 1. Try to load from local cache (Hive) first for instant display
  /// 2. If forceRefresh or cache is empty, fetch from API
  /// 3. Update cache with fresh data from API
  /// 
  /// This gives users instant feedback while ensuring data stays fresh.
  Future<List<AttendanceRecord>> getAttendance({
    String? classId,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    List<AttendanceRecord> records = [];

    // 1. Load from local cache if not forcing refresh
    if (!forceRefresh && _attendanceBox.isNotEmpty) {
      records = _loadFromCache(
        classId: classId,
        studentId: studentId,
        startDate: startDate,
        endDate: endDate,
      );
      
      if (records.isNotEmpty) {
        return records; // Return cached data immediately
      }
    }

    // 2. Fetch from API if cache is empty or refresh forced
    try {
      records = await _apiService.getAttendance(
        classId: classId,
        studentId: studentId,
        startDate: startDate,
        endDate: endDate,
      );

      // 3. Update local cache with fresh data
      await _updateCache(records);
      
      return records;
    } on DioException catch (e) {
      // If API fails, try to return cached data
      if (_attendanceBox.isNotEmpty) {
        records = _loadFromCache(
          classId: classId,
          studentId: studentId,
          startDate: startDate,
          endDate: endDate,
        );
        
        if (records.isNotEmpty) {
          // Return cached data but inform about network issue
          throw AppException('Network error, showing cached data. ${e.message}');
        }
      }
      throw AppException('Failed to fetch attendance: ${e.message}');
    } catch (e) {
      throw AppException('An unexpected error occurred: $e');
    }
  }

  /// Get a single attendance record by ID
  Future<AttendanceRecord?> getAttendanceRecord(String id) async {
    // Try cache first
    final recordData = _attendanceBox.get(id);
    if (recordData != null) {
      return AttendanceRecord.fromJson(Map<String, dynamic>.from(recordData));
    }

    // If not in cache, it might not exist or wasn't synced yet
    return null;
  }

  /// Create a new attendance record
  /// 
  /// Strategy: Save locally first, then sync to API
  /// This ensures the record is captured even if offline.
  Future<AttendanceRecord> createAttendance(AttendanceRecord record) async {
    try {
      // Save to local cache immediately
      await _attendanceBox.put(record.id, record.toJson());

      // Try to sync to API if online
      try {
        final serverRecord = await _apiService.createAttendance(record);
        
        // Mark as synced and update cache
        final syncedRecord = serverRecord.copyWith(synced: true);
        await _attendanceBox.put(syncedRecord.id, syncedRecord.toJson());
        
        return syncedRecord;
      } on DioException catch (e) {
        // If API fails, record is still saved locally
        // It will be synced later by OfflineQueueService
        print('API sync failed, record saved locally: ${e.message}');
      }

      return record;
    } catch (e) {
      throw AppException('Failed to create attendance record: $e');
    }
  }

  /// Update an existing attendance record
  Future<AttendanceRecord> updateAttendance(AttendanceRecord record) async {
    try {
      // Update local cache immediately
      final updatedRecord = record.copyWith(synced: false);
      await _attendanceBox.put(updatedRecord.id, updatedRecord.toJson());

      // Try to sync to API
      try {
        final serverRecord = await _apiService.updateAttendance(record.id, record);
        
        // Mark as synced
        final syncedRecord = serverRecord.copyWith(synced: true);
        
        await _attendanceBox.put(syncedRecord.id, syncedRecord.toJson());
        return syncedRecord;
      } on DioException catch (e) {
        print('API sync failed, update saved locally: ${e.message}');
      }

      return updatedRecord;
    } catch (e) {
      throw AppException('Failed to update attendance record: $e');
    }
  }

  /// Delete an attendance record
  Future<void> deleteAttendance(String recordId) async {
    try {
      // Delete from API first
      try {
        await _apiService.deleteAttendance(recordId);
      } on DioException catch (e) {
        print('API delete failed: ${e.message}');
      }
      
      // Delete from local cache regardless of API result
      await _attendanceBox.delete(recordId);
    } catch (e) {
      throw AppException('Failed to delete attendance record: $e');
    }
  }

  /// Get all unsynced records (for manual sync UI)
  Future<List<AttendanceRecord>> getUnsyncedRecords() async {
    final unsyncedRecords = <AttendanceRecord>[];
    
    for (final key in _attendanceBox.keys) {
      final recordData = _attendanceBox.get(key);
      if (recordData != null) {
        final record = AttendanceRecord.fromJson(
          Map<String, dynamic>.from(recordData),
        );
        
        if (!record.synced) {
          unsyncedRecords.add(record);
        }
      }
    }
    
    return unsyncedRecords;
  }

  /// Mark a record as synced (called after successful API sync)
  Future<void> markAsSynced(String recordId) async {
    final recordData = _attendanceBox.get(recordId);
    if (recordData != null) {
      final record = AttendanceRecord.fromJson(
        Map<String, dynamic>.from(recordData),
      );
      
      final syncedRecord = record.copyWith(synced: true);
      await _attendanceBox.put(recordId, syncedRecord.toJson());
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Load records from local cache with optional filters
  List<AttendanceRecord> _loadFromCache({
    String? classId,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final records = <AttendanceRecord>[];
    
    for (final key in _attendanceBox.keys) {
      final recordData = _attendanceBox.get(key);
      if (recordData != null) {
        final record = AttendanceRecord.fromJson(
          Map<String, dynamic>.from(recordData),
        );
        
        // Apply filters
        if (classId != null && record.classId != classId) continue;
        if (studentId != null && record.studentId != studentId) continue;
        if (startDate != null && record.timestamp.isBefore(startDate)) continue;
        if (endDate != null && record.timestamp.isAfter(endDate)) continue;
        
        records.add(record);
      }
    }
    
    // Sort by timestamp, newest first
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return records;
  }

  /// Update local cache with records from API
  Future<void> _updateCache(List<AttendanceRecord> records) async {
    for (final record in records) {
      await _attendanceBox.put(record.id, record.toJson());
    }
  }
}

