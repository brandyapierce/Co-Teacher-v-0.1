import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../data/models/attendance_record.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../../../core/network/app_exception.dart';
import 'attendance_list_state.dart';

/// Cubit (Business Logic Component) for managing attendance history
/// 
/// Think of this as the "manager" of the attendance list.
/// It handles:
/// - Loading attendance records from storage AND backend
/// - Applying filters and search
/// - Editing and deleting records
/// - Syncing local changes to backend
/// - Managing loading and error states
/// 
/// EDUCATIONAL NOTE - Evolution from direct Hive to Repository:
/// Previously, this Cubit talked directly to Hive storage. Now it uses
/// the AttendanceRepository which abstracts:
/// - Where data comes from (local cache vs API)
/// - How syncing works
/// - Error handling
/// 
/// This makes the Cubit simpler and more focused on UI logic.
class AttendanceListCubit extends Cubit<AttendanceListState> {
  final AttendanceRepository _repository = GetIt.instance<AttendanceRepository>();

  /// Constructor: Initialize with empty state
  AttendanceListCubit() : super(const AttendanceListState());

  /// Load all attendance records from repository
  /// 
  /// This is called when the page first opens.
  /// Pattern: Set loading → fetch data (from cache + API) → update state
  /// 
  /// If [forceRefresh] is true, bypass cache and fetch from API.
  /// The repository handles the offline-first strategy automatically.
  Future<void> loadRecords({bool forceRefresh = false}) async {
    // Step 1: Tell UI we're loading (shows loading spinner)
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Step 2: Get records from repository
      // The repository will try cache first, then API if needed
      final records = await _repository.getAttendance(
        forceRefresh: forceRefresh,
      );

      // Step 3: Update state with loaded records (UI rebuilds automatically)
      emit(state.copyWith(
        records: records,
        isLoading: false,
      ));
    } on AppException catch (e) {
      // Step 4: If something goes wrong, show error message
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      ));
    } catch (e) {
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
  /// Pattern: Find record → update it → save via repository → sync to backend
  /// The repository handles both local storage and API sync automatically.
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

      // Save via repository (handles local + API sync)
      await _repository.updateAttendance(updatedRecord);

      // Update our in-memory list
      final updatedRecords = List<AttendanceRecord>.from(state.records);
      updatedRecords[recordIndex] = updatedRecord;

      // Update state (UI rebuilds)
      emit(state.copyWith(records: updatedRecords));
    } on AppException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to edit record: $e',
      ));
    }
  }

  /// Delete an attendance record
  /// 
  /// Pattern: Delete via repository → remove from list → update UI
  /// The repository handles both local deletion and API sync.
  Future<void> deleteRecord(String recordId) async {
    try {
      // Delete via repository (handles local + API)
      await _repository.deleteAttendance(recordId);

      // Remove from our in-memory list
      final updatedRecords = state.records
          .where((r) => r.id != recordId)
          .toList();

      // Update state (UI rebuilds without the deleted record)
      emit(state.copyWith(records: updatedRecords));
    } on AppException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to delete record: $e',
      ));
    }
  }

  /// Refresh records (force reload from API)
  /// 
  /// This bypasses the cache and fetches fresh data from the backend.
  Future<void> refresh() async {
    await loadRecords(forceRefresh: true);
  }

  /// Get unsynced records count (for showing in UI)
  Future<int> getUnsyncedCount() async {
    try {
      final unsyncedRecords = await _repository.getUnsyncedRecords();
      return unsyncedRecords.length;
    } catch (e) {
      return 0;
    }
  }
}

