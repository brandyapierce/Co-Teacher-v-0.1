/// =============================================================================
/// ATTENDANCE STATISTICS MODELS
/// =============================================================================
/// 
/// LEARNING GUIDE: Data Models for Analytics
/// 
/// WHY SEPARATE MODELS FOR STATS?
/// - Raw attendance records are stored individually
/// - Statistics are computed/aggregated data
/// - Different structure optimized for display
/// - Cached separately for performance
/// 
/// DESIGN PATTERN: Value Objects
/// These are immutable data containers that hold computed results.
/// They don't have behavior, just data.
/// =============================================================================
library;

/// Time period for reports
enum ReportPeriod {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  thisQuarter('This Quarter'),
  thisYear('This Year'),
  custom('Custom Range');

  final String label;
  const ReportPeriod(this.label);

  /// Get date range for this period
  DateRange getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case ReportPeriod.today:
        return DateRange(today, today);
      
      case ReportPeriod.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return DateRange(weekStart, today);
      
      case ReportPeriod.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        return DateRange(monthStart, today);
      
      case ReportPeriod.lastMonth:
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0);
        return DateRange(lastMonthStart, lastMonthEnd);
      
      case ReportPeriod.thisQuarter:
        final quarter = ((now.month - 1) ~/ 3);
        final quarterStart = DateTime(now.year, quarter * 3 + 1, 1);
        return DateRange(quarterStart, today);
      
      case ReportPeriod.thisYear:
        final yearStart = DateTime(now.year, 1, 1);
        return DateRange(yearStart, today);
      
      case ReportPeriod.custom:
        return DateRange(today, today); // Will be overridden
    }
  }
}

/// Simple date range holder
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);

  /// Number of days in range
  int get dayCount => end.difference(start).inDays + 1;

  /// Format as string
  String get displayString {
    if (start == end) {
      return _formatDate(start);
    }
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// =============================================================================
/// ATTENDANCE STATISTICS - Aggregated data for a period
/// =============================================================================

class AttendanceStats {
  /// Total number of attendance records
  final int totalRecords;

  /// Number of "present" records
  final int presentCount;

  /// Number of "absent" records
  final int absentCount;

  /// Number of "tardy" records
  final int tardyCount;

  /// Number of "excused" records
  final int excusedCount;

  /// Date range for these statistics
  final DateRange dateRange;

  /// Class ID (null = all classes)
  final String? classId;

  /// When these stats were computed
  final DateTime computedAt;

  const AttendanceStats({
    required this.totalRecords,
    required this.presentCount,
    required this.absentCount,
    required this.tardyCount,
    required this.excusedCount,
    required this.dateRange,
    this.classId,
    required this.computedAt,
  });

  /// Create empty stats
  factory AttendanceStats.empty(DateRange range) {
    return AttendanceStats(
      totalRecords: 0,
      presentCount: 0,
      absentCount: 0,
      tardyCount: 0,
      excusedCount: 0,
      dateRange: range,
      computedAt: DateTime.now(),
    );
  }

  /// Attendance rate as percentage (0-100)
  double get attendanceRate {
    if (totalRecords == 0) return 0;
    return (presentCount / totalRecords) * 100;
  }

  /// Tardy rate as percentage
  double get tardyRate {
    if (totalRecords == 0) return 0;
    return (tardyCount / totalRecords) * 100;
  }

  /// Absence rate as percentage
  double get absenceRate {
    if (totalRecords == 0) return 0;
    return (absentCount / totalRecords) * 100;
  }

  /// Get color for attendance rate
  AttendanceRateLevel get rateLevel {
    if (attendanceRate >= 95) return AttendanceRateLevel.excellent;
    if (attendanceRate >= 90) return AttendanceRateLevel.good;
    if (attendanceRate >= 80) return AttendanceRateLevel.fair;
    return AttendanceRateLevel.poor;
  }

  /// Create from JSON (API response)
  factory AttendanceStats.fromJson(Map<String, dynamic> json, DateRange range) {
    return AttendanceStats(
      totalRecords: json['total_records'] as int? ?? 0,
      presentCount: json['present_count'] as int? ?? 0,
      absentCount: json['absent_count'] as int? ?? 0,
      tardyCount: json['tardy_count'] as int? ?? 0,
      excusedCount: json['excused_count'] as int? ?? 0,
      dateRange: range,
      classId: json['class_id'] as String?,
      computedAt: DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'total_records': totalRecords,
        'present_count': presentCount,
        'absent_count': absentCount,
        'tardy_count': tardyCount,
        'excused_count': excusedCount,
        'class_id': classId,
        'start_date': dateRange.start.toIso8601String(),
        'end_date': dateRange.end.toIso8601String(),
      };
}

/// Attendance rate classification
enum AttendanceRateLevel {
  excellent, // >= 95%
  good, // >= 90%
  fair, // >= 80%
  poor, // < 80%
}

/// =============================================================================
/// STUDENT ATTENDANCE SUMMARY - Per-student statistics
/// =============================================================================

class StudentAttendanceSummary {
  final String studentId;
  final String studentName;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int tardyDays;
  final int excusedDays;
  final DateTime? lastAttendance;

  const StudentAttendanceSummary({
    required this.studentId,
    required this.studentName,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.tardyDays,
    required this.excusedDays,
    this.lastAttendance,
  });

  /// Attendance rate as percentage
  double get attendanceRate {
    if (totalDays == 0) return 0;
    return (presentDays / totalDays) * 100;
  }

  /// Get status based on rate
  AttendanceRateLevel get status {
    if (attendanceRate >= 95) return AttendanceRateLevel.excellent;
    if (attendanceRate >= 90) return AttendanceRateLevel.good;
    if (attendanceRate >= 80) return AttendanceRateLevel.fair;
    return AttendanceRateLevel.poor;
  }

  factory StudentAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceSummary(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      totalDays: json['total_days'] as int? ?? 0,
      presentDays: json['present_days'] as int? ?? 0,
      absentDays: json['absent_days'] as int? ?? 0,
      tardyDays: json['tardy_days'] as int? ?? 0,
      excusedDays: json['excused_days'] as int? ?? 0,
      lastAttendance: json['last_attendance'] != null
          ? DateTime.parse(json['last_attendance'] as String)
          : null,
    );
  }
}

/// =============================================================================
/// DAILY ATTENDANCE TREND - For charts
/// =============================================================================

class DailyAttendanceTrend {
  final DateTime date;
  final int presentCount;
  final int absentCount;
  final int tardyCount;
  final int totalStudents;

  const DailyAttendanceTrend({
    required this.date,
    required this.presentCount,
    required this.absentCount,
    required this.tardyCount,
    required this.totalStudents,
  });

  double get attendanceRate {
    if (totalStudents == 0) return 0;
    return (presentCount / totalStudents) * 100;
  }

  factory DailyAttendanceTrend.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceTrend(
      date: DateTime.parse(json['date'] as String),
      presentCount: json['present_count'] as int? ?? 0,
      absentCount: json['absent_count'] as int? ?? 0,
      tardyCount: json['tardy_count'] as int? ?? 0,
      totalStudents: json['total_students'] as int? ?? 0,
    );
  }
}

/// =============================================================================
/// CLASS ATTENDANCE COMPARISON
/// =============================================================================

class ClassAttendanceComparison {
  final String classId;
  final String className;
  final double attendanceRate;
  final int studentCount;
  final String? color;

  const ClassAttendanceComparison({
    required this.classId,
    required this.className,
    required this.attendanceRate,
    required this.studentCount,
    this.color,
  });

  factory ClassAttendanceComparison.fromJson(Map<String, dynamic> json) {
    return ClassAttendanceComparison(
      classId: json['class_id'] as String,
      className: json['class_name'] as String,
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0,
      studentCount: json['student_count'] as int? ?? 0,
      color: json['color'] as String?,
    );
  }
}
