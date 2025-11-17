import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../data/repositories/student_repository.dart';
import 'student_list_state.dart';

/// Cubit for managing student list
/// 
/// EDUCATIONAL NOTE - Business Logic:
/// The cubit contains all the "what to do" logic:
/// - Load students from API
/// - Search/filter students
/// - Refresh data
/// - Handle errors
/// 
/// The UI just calls methods and reacts to state changes.

class StudentListCubit extends Cubit<StudentListState> {
  final StudentRepository _repository;

  StudentListCubit({
    StudentRepository? repository,
  })  : _repository = repository ?? GetIt.instance<StudentRepository>(),
        super(const StudentListState()) {
    // Load students when cubit is created
    loadStudents();
  }

  /// Load all students
  /// 
  /// EDUCATIONAL NOTE - Loading Pattern:
  /// 1. Emit loading state (show spinner)
  /// 2. Call repository (fetch data)
  /// 3. Emit success/error state (update UI)
  Future<void> loadStudents({String? classId}) async {
    emit(state.copyWith(status: StudentListStatus.loading));

    try {
      final students = await _repository.getStudents(classId: classId);

      emit(state.copyWith(
        status: StudentListStatus.success,
        students: students,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: StudentListStatus.error,
        errorMessage: 'Failed to load students: $e',
      ));
    }
  }

  /// Refresh students (pull-to-refresh)
  /// 
  /// Same as loadStudents but doesn't show loading spinner
  /// (RefreshIndicator shows its own spinner)
  Future<void> refreshStudents() async {
    try {
      final students = await _repository.getStudents(
        classId: state.classFilter,
      );

      emit(state.copyWith(
        status: StudentListStatus.success,
        students: students,
        errorMessage: null,
      ));
    } catch (e) {
      // Don't change status on refresh error
      // Just keep showing current data
      print('Refresh failed: $e');
    }
  }

  /// Update search query
  /// 
  /// EDUCATIONAL NOTE - Reactive Search:
  /// We don't call the API on every keystroke!
  /// Instead, we update the search query in state,
  /// and the filteredStudents getter does the filtering.
  /// 
  /// This is MUCH faster than calling API repeatedly.
  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  /// Clear search
  void clearSearch() {
    emit(state.copyWith(searchQuery: ''));
  }

  /// Filter by class
  void filterByClass(String? classId) {
    emit(state.copyWith(classFilter: classId));
    loadStudents(classId: classId);
  }

  /// Delete a student
  Future<bool> deleteStudent(String studentId) async {
    try {
      final success = await _repository.deleteStudent(studentId);

      if (success) {
        // Remove from local list
        final updatedList = state.students
            .where((s) => s.id != studentId)
            .toList();

        emit(state.copyWith(students: updatedList));
      }

      return success;
    } catch (e) {
      print('Error deleting student: $e');
      return false;
    }
  }

  /// Get cached student count (for offline indicator)
  int getCachedCount() {
    return _repository.getCachedStudentCount();
  }
}

