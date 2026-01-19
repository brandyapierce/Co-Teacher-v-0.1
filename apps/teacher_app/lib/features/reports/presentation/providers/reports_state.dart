import 'package:equatable/equatable.dart';
import '../../data/models/attendance_stats.dart';

/// =============================================================================
/// REPORTS STATE - Immutable state for reports dashboard
/// =============================================================================

class ReportsState extends Equatable {
  /// Overall attendance statistics
  final AttendanceStats? overallStats;

  /// Per-student summaries
  final List<StudentAttendanceSummary> studentSummaries;

  /// Daily trends for chart
  final List<DailyAttendanceTrend> dailyTrends;

  /// Class comparisons
  final List<ClassAttendanceComparison> classComparisons;

  /// Selected time period
  final ReportPeriod selectedPeriod;

  /// Custom date range (when period is custom)
  final DateRange? customDateRange;

  /// Selected class filter (null = all classes)
  final String? selectedClassId;

  /// Loading states
  final bool isLoadingStats;
  final bool isLoadingStudents;
  final bool isLoadingTrends;
  final bool isExporting;

  /// Error message
  final String? errorMessage;

  const ReportsState({
    this.overallStats,
    this.studentSummaries = const [],
    this.dailyTrends = const [],
    this.classComparisons = const [],
    this.selectedPeriod = ReportPeriod.thisWeek,
    this.customDateRange,
    this.selectedClassId,
    this.isLoadingStats = false,
    this.isLoadingStudents = false,
    this.isLoadingTrends = false,
    this.isExporting = false,
    this.errorMessage,
  });

  /// Initial state
  factory ReportsState.initial() => const ReportsState();

  /// Current active date range
  DateRange get activeDateRange {
    if (selectedPeriod == ReportPeriod.custom && customDateRange != null) {
      return customDateRange!;
    }
    return selectedPeriod.getDateRange();
  }

  /// Is any data loading?
  bool get isLoading => isLoadingStats || isLoadingStudents || isLoadingTrends;

  /// Has data been loaded?
  bool get hasData => overallStats != null;

  /// Students at risk (< 80% attendance)
  List<StudentAttendanceSummary> get studentsAtRisk {
    return studentSummaries
        .where((s) => s.attendanceRate < 80)
        .toList()
      ..sort((a, b) => a.attendanceRate.compareTo(b.attendanceRate));
  }

  /// Top performers (>= 95% attendance)
  List<StudentAttendanceSummary> get topPerformers {
    return studentSummaries
        .where((s) => s.attendanceRate >= 95)
        .toList()
      ..sort((a, b) => b.attendanceRate.compareTo(a.attendanceRate));
  }

  ReportsState copyWith({
    AttendanceStats? overallStats,
    List<StudentAttendanceSummary>? studentSummaries,
    List<DailyAttendanceTrend>? dailyTrends,
    List<ClassAttendanceComparison>? classComparisons,
    ReportPeriod? selectedPeriod,
    DateRange? customDateRange,
    bool clearCustomDateRange = false,
    String? selectedClassId,
    bool clearSelectedClass = false,
    bool? isLoadingStats,
    bool? isLoadingStudents,
    bool? isLoadingTrends,
    bool? isExporting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReportsState(
      overallStats: overallStats ?? this.overallStats,
      studentSummaries: studentSummaries ?? this.studentSummaries,
      dailyTrends: dailyTrends ?? this.dailyTrends,
      classComparisons: classComparisons ?? this.classComparisons,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      customDateRange: clearCustomDateRange ? null : (customDateRange ?? this.customDateRange),
      selectedClassId: clearSelectedClass ? null : (selectedClassId ?? this.selectedClassId),
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      isLoadingStudents: isLoadingStudents ?? this.isLoadingStudents,
      isLoadingTrends: isLoadingTrends ?? this.isLoadingTrends,
      isExporting: isExporting ?? this.isExporting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        overallStats,
        studentSummaries,
        dailyTrends,
        classComparisons,
        selectedPeriod,
        customDateRange,
        selectedClassId,
        isLoadingStats,
        isLoadingStudents,
        isLoadingTrends,
        isExporting,
        errorMessage,
      ];
}
