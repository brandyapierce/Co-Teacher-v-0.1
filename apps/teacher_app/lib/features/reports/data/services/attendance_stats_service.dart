import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import '../models/attendance_stats.dart';
import '../../../../core/network/api_client.dart';
import 'reports_api_service.dart';

/// =============================================================================
/// ATTENDANCE STATISTICS SERVICE
/// =============================================================================
/// 
/// LEARNING GUIDE: Service Layer Pattern
/// 
/// WHAT IS A SERVICE?
/// A service encapsulates business logic that doesn't belong in:
/// - Models (just data)
/// - Repositories (just data access)
/// - UI (just presentation)
/// 
/// WHY SEPARATE SERVICE FOR STATS?
/// - Complex calculations don't belong in UI
/// - Reusable across different screens
/// - Can compute from local cache OR fetch from API
/// - Easy to test in isolation
/// =============================================================================

class AttendanceStatsService {
  final ApiClient _apiClient;
  final ReportsApiService _reportsApiService;
  final Box _attendanceBox;

  AttendanceStatsService({
    ApiClient? apiClient,
    ReportsApiService? reportsApiService,
    Box? attendanceBox,
  })  : _apiClient = apiClient ?? GetIt.instance<ApiClient>(),
        _reportsApiService = reportsApiService ?? GetIt.instance<ReportsApiService>(),
        _attendanceBox = attendanceBox ?? 
            GetIt.instance<Box>(instanceName: 'attendance_records');

  // ==========================================================================
  // COMPUTE STATISTICS
  // ==========================================================================

  /// Get attendance statistics for a date range
  /// 
  /// LEARNING: Offline-first approach
  /// 1. First compute from local cache (instant)
  /// 2. Optionally fetch from API for accuracy
  Future<AttendanceStats> getStats({
    required DateRange dateRange,
    String? classId,
    bool useLocalOnly = false,
  }) async {
    // Try local computation first (fast)
    final localStats = _computeLocalStats(dateRange, classId);
    
    if (useLocalOnly || localStats.totalRecords > 0) {
      return localStats;
    }

    // Fetch from API if local is empty
    try {
      return await _reportsApiService.getAttendanceStats(
        dateRange: dateRange,
        classId: classId,
      );
    } catch (e) {
      // Return local stats on API failure
      return localStats;
    }
  }

  /// Compute statistics from local Hive cache
  AttendanceStats _computeLocalStats(DateRange dateRange, String? classId) {
    int presentCount = 0;
    int absentCount = 0;
    int tardyCount = 0;
    int excusedCount = 0;

    for (final record in _attendanceBox.values) {
      // Filter by date range
      final recordDate = record['timestamp'] != null
          ? DateTime.parse(record['timestamp'] as String)
          : null;
      
      if (recordDate == null) continue;
      
      if (recordDate.isBefore(dateRange.start) ||
          recordDate.isAfter(dateRange.end.add(const Duration(days: 1)))) {
        continue;
      }

      // Filter by class if specified
      if (classId != null && record['class_id'] != classId) {
        continue;
      }

      // Count by status
      final status = (record['status'] as String?)?.toLowerCase() ?? '';
      switch (status) {
        case 'present':
          presentCount++;
          break;
        case 'absent':
          absentCount++;
          break;
        case 'tardy':
        case 'late':
          tardyCount++;
          break;
        case 'excused':
          excusedCount++;
          break;
      }
    }

    final totalRecords = presentCount + absentCount + tardyCount + excusedCount;

    return AttendanceStats(
      totalRecords: totalRecords,
      presentCount: presentCount,
      absentCount: absentCount,
      tardyCount: tardyCount,
      excusedCount: excusedCount,
      dateRange: dateRange,
      classId: classId,
      computedAt: DateTime.now(),
    );
  }

  // ==========================================================================
  // STUDENT SUMMARIES
  // ==========================================================================

  /// Get attendance summary for each student
  Future<List<StudentAttendanceSummary>> getStudentSummaries({
    required DateRange dateRange,
    String? classId,
  }) async {
    // Group records by student
    final Map<String, Map<String, dynamic>> studentRecords = {};

    for (final record in _attendanceBox.values) {
      final recordDate = record['timestamp'] != null
          ? DateTime.parse(record['timestamp'] as String)
          : null;
      
      if (recordDate == null) continue;
      
      if (recordDate.isBefore(dateRange.start) ||
          recordDate.isAfter(dateRange.end.add(const Duration(days: 1)))) {
        continue;
      }

      if (classId != null && record['class_id'] != classId) {
        continue;
      }

      final studentId = record['student_id'] as String? ?? '';
      final studentName = record['student_name'] as String? ?? 'Unknown';
      final status = (record['status'] as String?)?.toLowerCase() ?? '';

      if (!studentRecords.containsKey(studentId)) {
        studentRecords[studentId] = {
          'student_id': studentId,
          'student_name': studentName,
          'present': 0,
          'absent': 0,
          'tardy': 0,
          'excused': 0,
          'last_attendance': recordDate,
        };
      }

      final data = studentRecords[studentId]!;
      switch (status) {
        case 'present':
          data['present'] = (data['present'] as int) + 1;
          break;
        case 'absent':
          data['absent'] = (data['absent'] as int) + 1;
          break;
        case 'tardy':
        case 'late':
          data['tardy'] = (data['tardy'] as int) + 1;
          break;
        case 'excused':
          data['excused'] = (data['excused'] as int) + 1;
          break;
      }

      // Track last attendance
      if (recordDate.isAfter(data['last_attendance'] as DateTime)) {
        data['last_attendance'] = recordDate;
      }
    }

    // Convert to summaries
    return studentRecords.values.map((data) {
      final total = (data['present'] as int) +
          (data['absent'] as int) +
          (data['tardy'] as int) +
          (data['excused'] as int);

      return StudentAttendanceSummary(
        studentId: data['student_id'] as String,
        studentName: data['student_name'] as String,
        totalDays: total,
        presentDays: data['present'] as int,
        absentDays: data['absent'] as int,
        tardyDays: data['tardy'] as int,
        excusedDays: data['excused'] as int,
        lastAttendance: data['last_attendance'] as DateTime?,
      );
    }).toList()
      ..sort((a, b) => a.studentName.compareTo(b.studentName));
  }

  // ==========================================================================
  // DAILY TRENDS
  // ==========================================================================

  /// Get daily attendance trends for charts
  Future<List<DailyAttendanceTrend>> getDailyTrends({
    required DateRange dateRange,
    String? classId,
  }) async {
    // Group records by date
    final Map<String, Map<String, int>> dailyData = {};

    for (final record in _attendanceBox.values) {
      final recordDate = record['timestamp'] != null
          ? DateTime.parse(record['timestamp'] as String)
          : null;
      
      if (recordDate == null) continue;
      
      if (recordDate.isBefore(dateRange.start) ||
          recordDate.isAfter(dateRange.end.add(const Duration(days: 1)))) {
        continue;
      }

      if (classId != null && record['class_id'] != classId) {
        continue;
      }

      final dateKey = '${recordDate.year}-${recordDate.month.toString().padLeft(2, '0')}-${recordDate.day.toString().padLeft(2, '0')}';
      
      if (!dailyData.containsKey(dateKey)) {
        dailyData[dateKey] = {
          'present': 0,
          'absent': 0,
          'tardy': 0,
          'total': 0,
        };
      }

      final data = dailyData[dateKey]!;
      final status = (record['status'] as String?)?.toLowerCase() ?? '';
      
      data['total'] = data['total']! + 1;
      switch (status) {
        case 'present':
          data['present'] = data['present']! + 1;
          break;
        case 'absent':
          data['absent'] = data['absent']! + 1;
          break;
        case 'tardy':
        case 'late':
          data['tardy'] = data['tardy']! + 1;
          break;
      }
    }

    // Convert to trend list and sort by date
    final trends = dailyData.entries.map((entry) {
      return DailyAttendanceTrend(
        date: DateTime.parse(entry.key),
        presentCount: entry.value['present'] ?? 0,
        absentCount: entry.value['absent'] ?? 0,
        tardyCount: entry.value['tardy'] ?? 0,
        totalStudents: entry.value['total'] ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return trends;
  }

  // ==========================================================================
  // CLASS COMPARISONS
  // ==========================================================================

  /// Get attendance comparison across classes
  Future<List<ClassAttendanceComparison>> getClassComparisons({
    required DateRange dateRange,
  }) async {
    // Group by class
    final Map<String, Map<String, dynamic>> classData = {};

    for (final record in _attendanceBox.values) {
      final recordDate = record['timestamp'] != null
          ? DateTime.parse(record['timestamp'] as String)
          : null;
      
      if (recordDate == null) continue;
      
      if (recordDate.isBefore(dateRange.start) ||
          recordDate.isAfter(dateRange.end.add(const Duration(days: 1)))) {
        continue;
      }

      final classId = record['class_id'] as String? ?? 'unknown';
      final className = record['class_name'] as String? ?? 'Unknown Class';
      final status = (record['status'] as String?)?.toLowerCase() ?? '';

      if (!classData.containsKey(classId)) {
        classData[classId] = {
          'class_id': classId,
          'class_name': className,
          'present': 0,
          'total': 0,
          'students': <String>{},
        };
      }

      final data = classData[classId]!;
      data['total'] = (data['total'] as int) + 1;
      
      if (status == 'present') {
        data['present'] = (data['present'] as int) + 1;
      }

      // Track unique students
      final studentId = record['student_id'] as String? ?? '';
      if (studentId.isNotEmpty) {
        (data['students'] as Set<String>).add(studentId);
      }
    }

    // Convert to comparisons
    return classData.values.map((data) {
      final total = data['total'] as int;
      final present = data['present'] as int;
      final rate = total > 0 ? (present / total) * 100 : 0.0;

      return ClassAttendanceComparison(
        classId: data['class_id'] as String,
        className: data['class_name'] as String,
        attendanceRate: rate,
        studentCount: (data['students'] as Set<String>).length,
      );
    }).toList()
      ..sort((a, b) => b.attendanceRate.compareTo(a.attendanceRate));
  }

  // ==========================================================================
  // QUICK STATS (for dashboard)
  // ==========================================================================

  /// Get today's quick stats
  Future<AttendanceStats> getTodayStats({String? classId}) async {
    final today = DateTime.now();
    final range = DateRange(
      DateTime(today.year, today.month, today.day),
      DateTime(today.year, today.month, today.day),
    );
    return getStats(dateRange: range, classId: classId, useLocalOnly: true);
  }

  /// Get this week's quick stats
  Future<AttendanceStats> getThisWeekStats({String? classId}) async {
    return getStats(
      dateRange: ReportPeriod.thisWeek.getDateRange(),
      classId: classId,
      useLocalOnly: true,
    );
  }

  /// Get this month's quick stats
  Future<AttendanceStats> getThisMonthStats({String? classId}) async {
    return getStats(
      dateRange: ReportPeriod.thisMonth.getDateRange(),
      classId: classId,
      useLocalOnly: true,
    );
  }
}
