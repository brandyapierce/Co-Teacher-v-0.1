import 'package:equatable/equatable.dart';
import '../../data/models/class_model.dart';

/// =============================================================================
/// CLASS LIST STATE - Immutable state for class list management
/// =============================================================================
/// 
/// LEARNING GUIDE: BLoC State Design
/// 
/// WHY IMMUTABLE STATE?
/// - Predictable: Can't accidentally modify state
/// - Easy to debug: Compare old vs new state
/// - Efficient: Flutter knows when to rebuild widgets
/// 
/// WHY EQUATABLE?
/// - Allows value comparison (not reference comparison)
/// - BlocBuilder uses this to decide when to rebuild
/// - Without it, UI might not update when state changes
/// =============================================================================

class ClassListState extends Equatable {
  /// List of all classes
  final List<ClassModel> classes;

  /// Whether data is currently loading
  final bool isLoading;

  /// Error message (null if no error)
  final String? errorMessage;

  /// Search query for filtering
  final String searchQuery;

  /// Currently selected class (for details view)
  final ClassModel? selectedClass;

  /// Whether we're in selection mode (for batch operations)
  final bool isSelectionMode;

  /// List of selected class IDs
  final List<String> selectedClassIds;

  const ClassListState({
    this.classes = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedClass,
    this.isSelectionMode = false,
    this.selectedClassIds = const [],
  });

  /// Initial/default state
  factory ClassListState.initial() => const ClassListState();

  /// Get filtered classes based on search query
  List<ClassModel> get filteredClasses {
    if (searchQuery.isEmpty) return classes;
    
    final query = searchQuery.toLowerCase();
    return classes.where((c) {
      return c.name.toLowerCase().contains(query) ||
          (c.subject?.toLowerCase().contains(query) ?? false) ||
          (c.gradeLevel?.toLowerCase().contains(query) ?? false) ||
          (c.room?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Total number of students across all classes
  int get totalStudents {
    return classes.fold(0, (sum, c) => sum + c.studentCount);
  }

  /// Number of active (visible) classes
  int get activeClassCount => classes.where((c) => c.isActive).length;

  /// Whether there are any selected classes
  bool get hasSelection => selectedClassIds.isNotEmpty;

  /// Number of selected classes
  int get selectionCount => selectedClassIds.length;

  /// Check if a class is selected
  bool isClassSelected(String classId) => selectedClassIds.contains(classId);

  /// Create a copy with updated fields
  ClassListState copyWith({
    List<ClassModel>? classes,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? searchQuery,
    ClassModel? selectedClass,
    bool clearSelectedClass = false,
    bool? isSelectionMode,
    List<String>? selectedClassIds,
  }) {
    return ClassListState(
      classes: classes ?? this.classes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedClass: clearSelectedClass ? null : (selectedClass ?? this.selectedClass),
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedClassIds: selectedClassIds ?? this.selectedClassIds,
    );
  }

  @override
  List<Object?> get props => [
        classes,
        isLoading,
        errorMessage,
        searchQuery,
        selectedClass,
        isSelectionMode,
        selectedClassIds,
      ];
}
