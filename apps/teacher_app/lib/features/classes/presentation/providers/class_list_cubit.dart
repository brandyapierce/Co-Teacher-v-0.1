import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../data/models/class_model.dart';
import '../../data/repositories/class_repository.dart';
import 'class_list_state.dart';

/// =============================================================================
/// CLASS LIST CUBIT - Business logic for class management
/// =============================================================================
/// 
/// LEARNING GUIDE: Cubit Pattern
/// 
/// WHAT IS A CUBIT?
/// A Cubit is a simpler version of BLoC that uses methods instead of events.
/// - Call methods directly (e.g., `cubit.loadClasses()`)
/// - State changes happen through `emit(newState)`
/// - Simpler than full BLoC for most CRUD operations
/// 
/// WHEN TO USE CUBIT VS BLOC:
/// - Cubit: Simple state changes, no complex event transformations
/// - BLoC: Complex event handling, debouncing, event-to-event mappings
/// =============================================================================

class ClassListCubit extends Cubit<ClassListState> {
  final ClassRepository _repository;
  final String teacherId;

  ClassListCubit({
    required this.teacherId,
    ClassRepository? repository,
  })  : _repository = repository ?? GetIt.instance<ClassRepository>(),
        super(ClassListState.initial());

  // ==========================================================================
  // LOAD OPERATIONS
  // ==========================================================================

  /// Load all classes for the teacher
  Future<void> loadClasses({bool forceRefresh = false}) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final classes = await _repository.getClasses(
        teacherId: teacherId,
        forceRefresh: forceRefresh,
      );

      emit(state.copyWith(
        classes: classes,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load classes: ${e.toString()}',
      ));
    }
  }

  /// Refresh classes from server
  Future<void> refresh() async {
    await loadClasses(forceRefresh: true);
  }

  // ==========================================================================
  // CREATE/UPDATE/DELETE OPERATIONS
  // ==========================================================================

  /// Create a new class
  Future<ClassModel?> createClass({
    required String name,
    String? gradeLevel,
    String? subject,
    String? room,
    String? academicYear,
    String? color,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final newClass = await _repository.createClass(
        name: name,
        teacherId: teacherId,
        gradeLevel: gradeLevel,
        subject: subject,
        room: room,
        academicYear: academicYear,
        color: color,
      );

      // Add to current list
      emit(state.copyWith(
        classes: [...state.classes, newClass],
        isLoading: false,
      ));

      return newClass;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create class: ${e.toString()}',
      ));
      return null;
    }
  }

  /// Update an existing class
  Future<bool> updateClass(ClassModel classModel) async {
    try {
      final updated = await _repository.updateClass(classModel);

      // Update in current list
      final updatedList = state.classes.map((c) {
        return c.id == updated.id ? updated : c;
      }).toList();

      emit(state.copyWith(
        classes: updatedList,
        selectedClass: state.selectedClass?.id == updated.id ? updated : null,
      ));

      return true;
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to update class: ${e.toString()}',
      ));
      return false;
    }
  }

  /// Delete a class
  Future<bool> deleteClass(String classId) async {
    try {
      await _repository.deleteClass(classId);

      // Remove from current list
      final updatedList = state.classes.where((c) => c.id != classId).toList();

      emit(state.copyWith(
        classes: updatedList,
        selectedClass: state.selectedClass?.id == classId ? null : state.selectedClass,
        clearSelectedClass: state.selectedClass?.id == classId,
        selectedClassIds: state.selectedClassIds.where((id) => id != classId).toList(),
      ));

      return true;
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to delete class: ${e.toString()}',
      ));
      return false;
    }
  }

  /// Delete multiple classes
  Future<void> deleteSelectedClasses() async {
    final idsToDelete = [...state.selectedClassIds];
    
    for (final id in idsToDelete) {
      await deleteClass(id);
    }
    
    exitSelectionMode();
  }

  // ==========================================================================
  // SEARCH & FILTER
  // ==========================================================================

  /// Update search query
  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  /// Clear search
  void clearSearch() {
    emit(state.copyWith(searchQuery: ''));
  }

  // ==========================================================================
  // SELECTION MODE
  // ==========================================================================

  /// Enter selection mode
  void enterSelectionMode() {
    emit(state.copyWith(isSelectionMode: true));
  }

  /// Exit selection mode and clear selections
  void exitSelectionMode() {
    emit(state.copyWith(
      isSelectionMode: false,
      selectedClassIds: [],
    ));
  }

  /// Toggle class selection
  void toggleClassSelection(String classId) {
    if (state.isClassSelected(classId)) {
      emit(state.copyWith(
        selectedClassIds: state.selectedClassIds.where((id) => id != classId).toList(),
      ));
    } else {
      emit(state.copyWith(
        selectedClassIds: [...state.selectedClassIds, classId],
      ));
    }
  }

  /// Select all classes
  void selectAll() {
    emit(state.copyWith(
      selectedClassIds: state.filteredClasses.map((c) => c.id).toList(),
    ));
  }

  /// Deselect all classes
  void deselectAll() {
    emit(state.copyWith(selectedClassIds: []));
  }

  // ==========================================================================
  // DETAIL VIEW
  // ==========================================================================

  /// Select a class for detail view
  void selectClass(ClassModel classModel) {
    emit(state.copyWith(selectedClass: classModel));
  }

  /// Clear selected class
  void clearSelectedClass() {
    emit(state.copyWith(clearSelectedClass: true));
  }

  // ==========================================================================
  // STUDENT MANAGEMENT
  // ==========================================================================

  /// Add a student to a class
  Future<bool> addStudentToClass(String classId, String studentId) async {
    try {
      final updated = await _repository.addStudentToClass(classId, studentId);
      if (updated == null) return false;

      // Update in current list
      final updatedList = state.classes.map((c) {
        return c.id == updated.id ? updated : c;
      }).toList();

      emit(state.copyWith(
        classes: updatedList,
        selectedClass: state.selectedClass?.id == updated.id ? updated : null,
      ));

      return true;
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to add student: ${e.toString()}',
      ));
      return false;
    }
  }

  /// Remove a student from a class
  Future<bool> removeStudentFromClass(String classId, String studentId) async {
    try {
      final updated = await _repository.removeStudentFromClass(classId, studentId);
      if (updated == null) return false;

      // Update in current list
      final updatedList = state.classes.map((c) {
        return c.id == updated.id ? updated : c;
      }).toList();

      emit(state.copyWith(
        classes: updatedList,
        selectedClass: state.selectedClass?.id == updated.id ? updated : null,
      ));

      return true;
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to remove student: ${e.toString()}',
      ));
      return false;
    }
  }

  /// Add multiple students to a class
  Future<bool> addStudentsToClass(String classId, List<String> studentIds) async {
    try {
      final updated = await _repository.addStudentsToClass(classId, studentIds);
      if (updated == null) return false;

      // Update in current list
      final updatedList = state.classes.map((c) {
        return c.id == updated.id ? updated : c;
      }).toList();

      emit(state.copyWith(
        classes: updatedList,
        selectedClass: state.selectedClass?.id == updated.id ? updated : null,
      ));

      return true;
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to add students: ${e.toString()}',
      ));
      return false;
    }
  }

  // ==========================================================================
  // ERROR HANDLING
  // ==========================================================================

  /// Clear error message
  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
