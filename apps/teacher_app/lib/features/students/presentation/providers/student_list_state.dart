import 'package:equatable/equatable.dart';
import '../../../../shared/data/models/student.dart';

/// State for the student list page
/// 
/// EDUCATIONAL NOTE - List State Pattern:
/// When managing lists, we track:
/// 1. The data (list of students)
/// 2. Loading status (are we fetching?)
/// 3. Errors (did something go wrong?)
/// 4. Search/filter state (what are we showing?)

enum StudentListStatus {
  initial,     // Nothing loaded yet
  loading,     // Fetching from API
  success,     // Data loaded successfully
  error,       // Something went wrong
}

class StudentListState extends Equatable {
  /// Current status
  final StudentListStatus status;
  
  /// All students (unfiltered)
  final List<Student> students;
  
  /// Error message if status is error
  final String? errorMessage;
  
  /// Search query for filtering
  final String searchQuery;
  
  /// Selected class filter
  final String? classFilter;

  const StudentListState({
    this.status = StudentListStatus.initial,
    this.students = const [],
    this.errorMessage,
    this.searchQuery = '',
    this.classFilter,
  });

  /// Filtered students based on search query
  /// 
  /// EDUCATIONAL NOTE - Computed Properties:
  /// This is a "getter" that calculates filtered students on-the-fly.
  /// We don't store filtered list separately - we compute it when needed.
  /// 
  /// WHY?
  /// - Saves memory (only one list stored)
  /// - Always up-to-date (no sync issues)
  /// - Simpler state management
  List<Student> get filteredStudents {
    var filtered = students;

    // Filter by class if specified
    if (classFilter != null && classFilter!.isNotEmpty) {
      filtered = filtered.where((s) => s.classId == classFilter).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((student) {
        return student.fullName.toLowerCase().contains(query) ||
               student.email?.toLowerCase().contains(query) == true ||
               student.grade?.toLowerCase().contains(query) == true;
      }).toList();
    }

    return filtered;
  }

  /// Count of filtered students
  int get filteredCount => filteredStudents.length;

  /// Are we currently loading?
  bool get isLoading => status == StudentListStatus.loading;

  /// Do we have an error?
  bool get hasError => status == StudentListStatus.error;

  /// Is the list empty?
  bool get isEmpty => students.isEmpty;

  /// Copy with new values
  StudentListState copyWith({
    StudentListStatus? status,
    List<Student>? students,
    String? errorMessage,
    String? searchQuery,
    String? classFilter,
  }) {
    return StudentListState(
      status: status ?? this.status,
      students: students ?? this.students,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      classFilter: classFilter ?? this.classFilter,
    );
  }

  @override
  List<Object?> get props => [
        status,
        students,
        errorMessage,
        searchQuery,
        classFilter,
      ];
}

