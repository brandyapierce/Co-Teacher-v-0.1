import 'package:get_it/get_it.dart';
import '../../../../core/network/api_client.dart';
import '../models/attendance_stats.dart';

/// =============================================================================
/// REPORTS API SERVICE
/// =============================================================================
/// 
/// LEARNING GUIDE: API Service Layer
/// 
/// WHAT IS AN API SERVICE?
/// - Abstracts HTTP calls to backend
/// - Handles response parsing
/// - Returns domain models
/// - Separate from UI and repository
/// 
/// WHY SEPARATE FROM API CLIENT?
/// - API client: Generic HTTP calls
/// - API service: Domain-specific logic
/// - Example: API client does POST, service knows what to POST
/// =============================================================================

class ReportsApiService {
  final ApiClient _apiClient;

  ReportsApiService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? GetIt.instance<ApiClient>();

  // ==========================================================================
  // ATTENDANCE STATISTICS
  // ==========================================================================

  /// Get overall attendance statistics
  Future<AttendanceStats> getAttendanceStats({
    required DateRange dateRange,
    String? classId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/reports/attendance/stats',
        queryParameters: {
          'start_date': dateRange.start.toIso8601String(),
          'end_date': dateRange.end.toIso8601String(),
          if (classId != null) 'class_id': classId,
        },
      );

      return AttendanceStats.fromJson(
        response.data as Map<String, dynamic>,
        dateRange,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get per-student attendance summaries
  Future<List<StudentAttendanceSummary>> getStudentSummaries({
    required DateRange dateRange,
    String? classId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/reports/student-summaries',
        queryParameters: {
          'start_date': dateRange.start.toIso8601String(),
          'end_date': dateRange.end.toIso8601String(),
          if (classId != null) 'class_id': classId,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final summariesJson = data['summaries'] as List<dynamic>? ?? [];

      return summariesJson
          .map((item) => StudentAttendanceSummary.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get daily attendance trends for charting
  Future<List<DailyAttendanceTrend>> getDailyTrends({
    required DateRange dateRange,
    String? classId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/reports/daily-trends',
        queryParameters: {
          'start_date': dateRange.start.toIso8601String(),
          'end_date': dateRange.end.toIso8601String(),
          if (classId != null) 'class_id': classId,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final trendsJson = data['trends'] as List<dynamic>? ?? [];

      return trendsJson
          .map((item) => DailyAttendanceTrend.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get attendance comparison across classes
  Future<List<ClassAttendanceComparison>> getClassComparisons({
    required DateRange dateRange,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/reports/class-comparisons',
        queryParameters: {
          'start_date': dateRange.start.toIso8601String(),
          'end_date': dateRange.end.toIso8601String(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      final comparisonsJson = data['comparisons'] as List<dynamic>? ?? [];

      return comparisonsJson
          .map((item) => ClassAttendanceComparison.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================================================
  // INSIGHTS & PATTERNS
  // ==========================================================================

  /// Get identified attendance patterns
  Future<Map<String, dynamic>> getPatterns({
    required DateRange dateRange,
    String? classId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/reports/patterns',
        queryParameters: {
          'start_date': dateRange.start.toIso8601String(),
          'end_date': dateRange.end.toIso8601String(),
          if (classId != null) 'class_id': classId,
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get student performance report
  Future<Map<String, dynamic>> getPerformanceReport({
    required DateRange dateRange,
    String? classId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/reports/performance',
        queryParameters: {
          'start_date': dateRange.start.toIso8601String(),
          'end_date': dateRange.end.toIso8601String(),
          if (classId != null) 'class_id': classId,
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================================================
  // COMPREHENSIVE REPORT
  // ==========================================================================

  /// Get complete analytics report
  Future<Map<String, dynamic>> getComprehensiveReport({
    required DateRange dateRange,
    String? classId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/reports/comprehensive',
        queryParameters: {
          'start_date': dateRange.start.toIso8601String(),
          'end_date': dateRange.end.toIso8601String(),
          if (classId != null) 'class_id': classId,
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================================================
  // EXPORT
  // ==========================================================================

  /// Export report to CSV
  Future<String> exportToCsv({
    required DateRange dateRange,
    String? classId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/reports/export/csv',
        queryParameters: {
          'start_date': dateRange.start.toIso8601String(),
          'end_date': dateRange.end.toIso8601String(),
          if (classId != null) 'class_id': classId,
        },
      );

      return response.data['csv_content'] as String? ?? '';
    } catch (e) {
      rethrow;
    }
  }

  /// Export report to PDF
  Future<String> exportToPdf({
    required DateRange dateRange,
    String? classId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/reports/export/pdf',
        queryParameters: {
          'start_date': dateRange.start.toIso8601String(),
          'end_date': dateRange.end.toIso8601String(),
          if (classId != null) 'class_id': classId,
        },
      );

      return response.data['data'] as String? ?? '';
    } catch (e) {
      rethrow;
    }
  }
}
