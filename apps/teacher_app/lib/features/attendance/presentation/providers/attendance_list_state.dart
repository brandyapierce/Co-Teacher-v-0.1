import 'package:equatable/equatable.dart';
import '../../data/models/attendance_record.dart';

/// State for attendance list page
/// 
/// This class represents everything the UI needs to display the attendance history.
/// We use Equatable to make state comparison easy - Flutter rebuilds UI only when state changes.
class AttendanceListState extends Equatable {
  /// List of all attendance records (can be filtered)
  final List<AttendanceRecord> records;
  
  /// Whether we're currently loading data
  final bool isLoading;
  
  /// Error message if something went wrong
  final String? errorMessage;
  
  /// Currently applied filters
  final AttendanceFilters filters;
  
  /// Search query for student names
  final String searchQuery;

  const AttendanceListState({
    this.records = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filters = const AttendanceFilters(),
    this.searchQuery = '',
  });

  /// Computed property: Get the filtered list based on current filters and search
  /// This is called whenever the UI needs to display records
  List<AttendanceRecord> get filteredRecords {
    var filtered = records;

    // Apply status filter (present, absent, tardy)
    if (filters.status != null) {
      filtered = filtered.where((r) => r.status == filters.status).toList();
    }

    // Apply date range filter
    if (filters.startDate != null) {
      filtered = filtered
          .where((r) => r.timestamp.isAfter(filters.startDate!))
          .toList();
    }
    if (filters.endDate != null) {
      filtered = filtered
          .where((r) => r.timestamp.isBefore(filters.endDate!))
          .toList();
    }

    // Apply class filter
    if (filters.classId != null) {
      filtered = filtered.where((r) => r.classId == filters.classId).toList();
    }

    // Apply search query (search in student names)
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((r) => r.studentName.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    // Sort by timestamp (newest first)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered;
  }

  /// Get count of records matching current filters
  int get filteredCount => filteredRecords.length;

  /// Check if any filters are active
  bool get hasActiveFilters =>
      filters.status != null ||
      filters.startDate != null ||
      filters.endDate != null ||
      filters.classId != null ||
      searchQuery.isNotEmpty;

  /// Create a copy of this state with some fields changed
  /// This is the core of immutable state management
  AttendanceListState copyWith({
    List<AttendanceRecord>? records,
    bool? isLoading,
    String? errorMessage,
    AttendanceFilters? filters,
    String? searchQuery,
  }) {
    return AttendanceListState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filters: filters ?? this.filters,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Equatable requires us to list which properties to compare
  /// If any of these change, Flutter knows to rebuild the UI
  @override
  List<Object?> get props => [
        records,
        isLoading,
        errorMessage,
        filters,
        searchQuery,
      ];
}

/// Filter options for attendance records
/// Separated into its own class for better organization
class AttendanceFilters extends Equatable {
  final String? status; // 'present', 'absent', 'tardy', or null (all)
  final DateTime? startDate; // Filter records after this date
  final DateTime? endDate; // Filter records before this date
  final String? classId; // Filter by specific class

  const AttendanceFilters({
    this.status,
    this.startDate,
    this.endDate,
    this.classId,
  });

  /// Create a copy with some filters changed
  AttendanceFilters copyWith({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? classId,
    bool clearStatus = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearClassId = false,
  }) {
    return AttendanceFilters(
      status: clearStatus ? null : (status ?? this.status),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      classId: clearClassId ? null : (classId ?? this.classId),
    );
  }

  /// Clear all filters
  AttendanceFilters clearAll() {
    return const AttendanceFilters();
  }

  @override
  List<Object?> get props => [status, startDate, endDate, classId];
}

