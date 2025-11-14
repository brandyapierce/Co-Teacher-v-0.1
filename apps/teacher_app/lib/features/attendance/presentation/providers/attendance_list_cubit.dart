import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../data/models/attendance_record.dart';
import 'attendance_list_state.dart';

/// Cubit (Business Logic Component) for managing attendance history
/// 
/// Think of this as the "manager" of the attendance list.
/// It handles:
/// - Loading attendance records from storage
/// - Applying filters and search
/// - Editing and deleting records
/// - Managing loading and error states
class AttendanceListCubit extends Cubit<AttendanceListState> {
  final Box _attendanceBox;

  /// Constructor: Initialize with empty state
  /// We pass in the Hive box so this cubit can access stored data
  AttendanceListCubit({
    required Box attendanceBox,
  })  : _attendanceBox = attendanceBox,
        super(const AttendanceListState());

  /// Load all attendance records from storage
  /// 
  /// This is called when the page first opens.
  /// Pattern: Set loading → fetch data → update state with data
  Future<void> loadRecords() async {
    // Step 1: Tell UI we're loading (shows loading spinner)
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Step 2: Get all records from Hive storage
      final records = <AttendanceRecord>[];
      
      // Hive stores data as key-value pairs
      // We iterate through all keys and convert data to AttendanceRecord objects
      for (final key in _attendanceBox.keys) {
        final data = _attendanceBox.get(key);
        if (data != null) {
          // Each record is stored as JSON (Map<String, dynamic>)
          final record = AttendanceRecord.fromJson(
            Map<String, dynamic>.from(data as Map),
          );
          records.add(record);
        }
      }

      // Step 3: Update state with loaded records (UI rebuilds automatically)
      emit(state.copyWith(
        records: records,
        isLoading: false,
      ));
    } catch (e) {
      // Step 4: If something goes wrong, show error message
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load records: $e',
      ));
    }
  }

  /// Update the search query
  /// 
  /// Called when user types in the search box.
  /// The UI automatically shows filtered results (via state.filteredRecords)
  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  /// Apply a filter (e.g., filter by status: "present" only)
  /// 
  /// This doesn't reload data - it just updates the filter in state.
  /// The UI uses state.filteredRecords which applies filters on-the-fly.
  void applyFilters(AttendanceFilters filters) {
    emit(state.copyWith(filters: filters));
  }

  /// Filter by status (present, absent, tardy)
  void filterByStatus(String? status) {
    final newFilters = state.filters.copyWith(
      status: status,
      clearStatus: status == null,
    );
    emit(state.copyWith(filters: newFilters));
  }

  /// Filter by date range
  void filterByDateRange(DateTime? start, DateTime? end) {
    final newFilters = state.filters.copyWith(
      startDate: start,
      endDate: end,
      clearStartDate: start == null,
      clearEndDate: end == null,
    );
    emit(state.copyWith(filters: newFilters));
  }

  /// Filter by class
  void filterByClass(String? classId) {
    final newFilters = state.filters.copyWith(
      classId: classId,
      clearClassId: classId == null,
    );
    emit(state.copyWith(filters: newFilters));
  }

  /// Clear all filters and search
  void clearFilters() {
    emit(state.copyWith(
      filters: state.filters.clearAll(),
      searchQuery: '',
    ));
  }

  /// Edit an attendance record
  /// 
  /// Pattern: Find record → update it → save to storage → reload UI
  Future<void> editRecord(String recordId, {
    String? status,
    String? notes,
  }) async {
    try {
      // Find the record in our current list
      final recordIndex = state.records.indexWhere((r) => r.id == recordId);
      if (recordIndex == -1) return; // Record not found

      final oldRecord = state.records[recordIndex];
      
      // Create updated record (immutable - we create a new one)
      final updatedRecord = oldRecord.copyWith(
        status: status ?? oldRecord.status,
        notes: notes ?? oldRecord.notes,
      );

      // Save to Hive storage
      await _attendanceBox.put(recordId, updatedRecord.toJson());

      // Update our in-memory list
      final updatedRecords = List<AttendanceRecord>.from(state.records);
      updatedRecords[recordIndex] = updatedRecord;

      // Update state (UI rebuilds)
      emit(state.copyWith(records: updatedRecords));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to edit record: $e',
      ));
    }
  }

  /// Delete an attendance record
  /// 
  /// Pattern: Remove from storage → remove from list → update UI
  Future<void> deleteRecord(String recordId) async {
    try {
      // Remove from Hive storage
      await _attendanceBox.delete(recordId);

      // Remove from our in-memory list
      final updatedRecords = state.records
          .where((r) => r.id != recordId)
          .toList();

      // Update state (UI rebuilds without the deleted record)
      emit(state.copyWith(records: updatedRecords));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to delete record: $e',
      ));
    }
  }

  /// Refresh records (pull from storage again)
  Future<void> refresh() async {
    await loadRecords();
  }
}

