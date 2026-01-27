import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/attendance_stats.dart';
import '../../data/services/attendance_stats_service.dart';
import 'reports_state.dart';

/// =============================================================================
/// REPORTS CUBIT - Business logic for reports dashboard
/// =============================================================================
/// 
/// LEARNING GUIDE: Cubit for Complex Data Loading
/// 
/// PATTERN: Parallel Data Loading
/// - Load multiple data sources simultaneously
/// - Update UI as each completes
/// - Better UX than sequential loading
/// =============================================================================

class ReportsCubit extends Cubit<ReportsState> {
  final AttendanceStatsService _statsService;

  ReportsCubit({
    AttendanceStatsService? statsService,
  })  : _statsService = statsService ?? AttendanceStatsService(),
        super(ReportsState.initial());

  // ==========================================================================
  // LOAD DATA
  // ==========================================================================

  /// Load all report data for current period
  Future<void> loadReports() async {
    emit(state.copyWith(
      isLoadingStats: true,
      isLoadingStudents: true,
      isLoadingTrends: true,
      clearError: true,
    ));

    final dateRange = state.activeDateRange;
    final classId = state.selectedClassId;

    // Load all data in parallel
    await Future.wait([
      _loadOverallStats(dateRange, classId),
      _loadStudentSummaries(dateRange, classId),
      _loadDailyTrends(dateRange, classId),
      _loadClassComparisons(dateRange),
    ]);
  }

  Future<void> _loadOverallStats(DateRange dateRange, String? classId) async {
    try {
      final stats = await _statsService.getStats(
        dateRange: dateRange,
        classId: classId,
      );
      emit(state.copyWith(
        overallStats: stats,
        isLoadingStats: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingStats: false,
        errorMessage: 'Failed to load statistics: $e',
      ));
    }
  }

  Future<void> _loadStudentSummaries(DateRange dateRange, String? classId) async {
    try {
      final summaries = await _statsService.getStudentSummaries(
        dateRange: dateRange,
        classId: classId,
      );
      emit(state.copyWith(
        studentSummaries: summaries,
        isLoadingStudents: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingStudents: false,
        errorMessage: 'Failed to load student summaries: $e',
      ));
    }
  }

  Future<void> _loadDailyTrends(DateRange dateRange, String? classId) async {
    try {
      final trends = await _statsService.getDailyTrends(
        dateRange: dateRange,
        classId: classId,
      );
      emit(state.copyWith(
        dailyTrends: trends,
        isLoadingTrends: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingTrends: false,
        errorMessage: 'Failed to load trends: $e',
      ));
    }
  }

  Future<void> _loadClassComparisons(DateRange dateRange) async {
    try {
      final comparisons = await _statsService.getClassComparisons(
        dateRange: dateRange,
      );
      emit(state.copyWith(classComparisons: comparisons));
    } catch (e) {
      // Non-critical, don't show error
    }
  }

  // ==========================================================================
  // FILTERS
  // ==========================================================================

  /// Change the selected time period
  void selectPeriod(ReportPeriod period) {
    emit(state.copyWith(
      selectedPeriod: period,
      clearCustomDateRange: period != ReportPeriod.custom,
    ));
    loadReports();
  }

  /// Set custom date range
  void setCustomDateRange(DateRange range) {
    emit(state.copyWith(
      selectedPeriod: ReportPeriod.custom,
      customDateRange: range,
    ));
    loadReports();
  }

  /// Filter by class
  void filterByClass(String? classId) {
    emit(state.copyWith(
      selectedClassId: classId,
      clearSelectedClass: classId == null,
    ));
    loadReports();
  }

  // ==========================================================================
  // EXPORT
  // ==========================================================================

  /// Export report as CSV
  Future<String?> exportToCsv() async {
    if (!state.hasData) return null;

    emit(state.copyWith(isExporting: true));

    try {
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln('Co-Teacher Attendance Report');
      buffer.writeln('Period: ${state.selectedPeriod.label}');
      buffer.writeln('Date Range: ${state.activeDateRange.displayString}');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln();

      // Overall stats
      if (state.overallStats != null) {
        final stats = state.overallStats!;
        buffer.writeln('Summary Statistics');
        buffer.writeln('Total Records,${stats.totalRecords}');
        buffer.writeln('Present,${stats.presentCount}');
        buffer.writeln('Absent,${stats.absentCount}');
        buffer.writeln('Tardy,${stats.tardyCount}');
        buffer.writeln('Attendance Rate,${stats.attendanceRate.toStringAsFixed(1)}%');
        buffer.writeln();
      }

      // Student summaries
      if (state.studentSummaries.isNotEmpty) {
        buffer.writeln('Student Details');
        buffer.writeln('Student Name,Total Days,Present,Absent,Tardy,Attendance Rate');
        for (final student in state.studentSummaries) {
          buffer.writeln(
            '${student.studentName},'
            '${student.totalDays},'
            '${student.presentDays},'
            '${student.absentDays},'
            '${student.tardyDays},'
            '${student.attendanceRate.toStringAsFixed(1)}%'
          );
        }
      }

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/attendance_report_$timestamp.csv');
      await file.writeAsString(buffer.toString());

      emit(state.copyWith(isExporting: false));
      return file.path;
    } catch (e) {
      emit(state.copyWith(
        isExporting: false,
        errorMessage: 'Failed to export: $e',
      ));
      return null;
    }
  }

  // ==========================================================================
  // ERROR HANDLING
  // ==========================================================================

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
