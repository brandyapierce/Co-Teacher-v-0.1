import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/attendance_record.dart';

/// Attendance API Service
/// 
/// Handles all attendance-related API calls to the backend.
/// Manages sync between local storage (Hive) and backend database (PostgreSQL).
/// 
/// EDUCATIONAL NOTE - Offline-First Architecture:
/// This service implements offline-first strategy:
/// 1. Save locally first (Hive) for instant feedback
/// 2. Sync to backend when online
/// 3. Queue for later if offline
/// 4. Retry failed syncs automatically
class AttendanceApiService {
  final ApiClient _apiClient;

  AttendanceApiService(this._apiClient);

  /// Create attendance record on backend
  /// 
  /// POST /api/v1/attendance/scan
  /// Returns the created attendance record with server-generated data
  Future<AttendanceRecord> createAttendance(AttendanceRecord record) async {
    try {
      final response = await _apiClient.createAttendance(record.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Backend might return the created record with additional fields
        if (response.data is Map<String, dynamic>) {
          return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
        }
        // If backend just returns success, return the original record marked as synced
        return record.copyWith(synced: true);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to create attendance: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Batch create multiple attendance records
  /// 
  /// Useful for syncing offline queue
  Future<List<AttendanceRecord>> createAttendanceBatch(
    List<AttendanceRecord> records,
  ) async {
    try {
      final recordsJson = records.map((r) => r.toJson()).toList();
      final response = await _apiClient.createAttendanceBatch(recordsJson);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => AttendanceRecord.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to create attendance batch: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get attendance records from backend
  /// 
  /// GET /api/v1/attendance/records
  /// Supports filtering by class, student, date range
  Future<List<AttendanceRecord>> getAttendance({
    String? classId,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiClient.getAttendance(
        classId: classId,
        studentId: studentId,
        startDate: startDate,
        endDate: endDate,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => AttendanceRecord.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load attendance: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update attendance record on backend
  /// 
  /// PUT /api/v1/attendance/{id}
  Future<AttendanceRecord> updateAttendance(
    String attendanceId,
    AttendanceRecord record,
  ) async {
    try {
      final response = await _apiClient.updateAttendance(
        attendanceId,
        record.toJson(),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
        }
        return record.copyWith(synced: true);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to update attendance: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete attendance record from backend
  /// 
  /// DELETE /api/v1/attendance/{id}
  Future<void> deleteAttendance(String attendanceId) async {
    try {
      final response = await _apiClient.deleteAttendance(attendanceId);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to delete attendance: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check if backend is reachable
  /// 
  /// Useful for determining if we should attempt sync
  Future<bool> isBackendAvailable() async {
    try {
      final response = await _apiClient.healthCheck();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

