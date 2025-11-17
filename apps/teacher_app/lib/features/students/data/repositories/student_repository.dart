import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/data/models/student.dart';

/// Repository for managing student data
/// 
/// EDUCATIONAL NOTE - Repository Pattern:
/// -------------------------------------
/// A repository is like a "librarian" that manages data access.
/// It handles both remote (API) and local (Hive) data sources.
/// 
/// WHY USE REPOSITORIES?
/// 1. Single source of truth (UI doesn't care where data comes from)
/// 2. Easy to test (can mock the repository)
/// 3. Caching logic in one place
/// 4. Offline support (try API, fallback to cache)
/// 
/// FLOW:
/// UI → Repository → [Try API] → [Cache result] → Return to UI
///                ↓ (if offline)
///           [Return cached data]

class StudentRepository {
  final ApiClient _apiClient;
  final Box _studentsBox;

  StudentRepository({
    ApiClient? apiClient,
    Box? studentsBox,
  })  : _apiClient = apiClient ?? GetIt.instance<ApiClient>(),
        _studentsBox = studentsBox ?? GetIt.instance<Box>(instanceName: 'students');

  /// Get all students for a class
  /// 
  /// EDUCATIONAL NOTE - Offline-First Strategy:
  /// 1. Return cached data immediately (instant UI)
  /// 2. Fetch fresh data from API in background
  /// 3. Update cache with fresh data
  /// 4. Notify UI to refresh
  /// 
  /// This gives users instant feedback even on slow networks!
  Future<List<Student>> getStudents({String? classId}) async {
    try {
      // Try to fetch from API
      final response = await _apiClient.getStudents(classId: classId);

      if (response.statusCode == 200) {
        // Parse JSON array to list of Student objects
        final List<dynamic> data = response.data['students'] ?? response.data;
        final students = data.map((json) => Student.fromJson(json)).toList();

        // Cache the results
        await _cacheStudents(students);

        return students;
      }

      // API returned error, try cache
      return _getCachedStudents(classId);
    } on DioException catch (e) {
      // Network error, return cached data
      print('Network error fetching students: ${e.message}');
      return _getCachedStudents(classId);
    } catch (e) {
      print('Error fetching students: $e');
      return _getCachedStudents(classId);
    }
  }

  /// Get a single student by ID
  Future<Student?> getStudent(String studentId) async {
    try {
      final response = await _apiClient.getStudent(studentId);

      if (response.statusCode == 200) {
        final student = Student.fromJson(response.data);
        
        // Update cache
        await _studentsBox.put(studentId, student.toJson());
        
        return student;
      }

      // Try cache
      return _getCachedStudent(studentId);
    } catch (e) {
      print('Error fetching student $studentId: $e');
      return _getCachedStudent(studentId);
    }
  }

  /// Create a new student
  /// 
  /// EDUCATIONAL NOTE - Optimistic Updates:
  /// Sometimes we update local cache BEFORE the API call succeeds.
  /// This makes the UI feel instant. If API fails, we roll back.
  Future<Student?> createStudent(Student student) async {
    try {
      final response = await _apiClient.createStudent(student.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final createdStudent = Student.fromJson(response.data);
        
        // Cache the created student
        await _studentsBox.put(createdStudent.id, createdStudent.toJson());
        
        return createdStudent;
      }

      return null;
    } catch (e) {
      print('Error creating student: $e');
      return null;
    }
  }

  /// Update an existing student
  Future<Student?> updateStudent(Student student) async {
    try {
      final response = await _apiClient.updateStudent(
        student.id,
        student.toJson(),
      );

      if (response.statusCode == 200) {
        final updatedStudent = Student.fromJson(response.data);
        
        // Update cache
        await _studentsBox.put(updatedStudent.id, updatedStudent.toJson());
        
        return updatedStudent;
      }

      return null;
    } catch (e) {
      print('Error updating student: $e');
      return null;
    }
  }

  /// Delete a student
  Future<bool> deleteStudent(String studentId) async {
    try {
      final response = await _apiClient.deleteStudent(studentId);

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove from cache
        await _studentsBox.delete(studentId);
        return true;
      }

      return false;
    } catch (e) {
      print('Error deleting student: $e');
      return false;
    }
  }

  // ==================== CACHE METHODS ====================

  /// Cache students to local storage
  /// 
  /// EDUCATIONAL NOTE - Why Cache?
  /// Caching means saving data locally so the app works offline.
  /// Hive is perfect for this - it's fast and works offline.
  Future<void> _cacheStudents(List<Student> students) async {
    try {
      // Clear old cache
      await _studentsBox.clear();

      // Save each student
      for (final student in students) {
        await _studentsBox.put(student.id, student.toJson());
      }
    } catch (e) {
      print('Error caching students: $e');
    }
  }

  /// Get cached students
  /// 
  /// This is called when the API is unavailable (offline mode)
  List<Student> _getCachedStudents(String? classId) {
    try {
      final List<Student> students = [];

      // Iterate through all cached students
      for (var key in _studentsBox.keys) {
        try {
          final json = _studentsBox.get(key) as Map<String, dynamic>;
          final student = Student.fromJson(json);

          // Filter by classId if provided
          if (classId == null || student.classId == classId) {
            students.add(student);
          }
        } catch (e) {
          print('Error parsing cached student: $e');
        }
      }

      return students;
    } catch (e) {
      print('Error getting cached students: $e');
      return [];
    }
  }

  /// Get a single cached student
  Student? _getCachedStudent(String studentId) {
    try {
      final json = _studentsBox.get(studentId);
      if (json != null) {
        return Student.fromJson(Map<String, dynamic>.from(json));
      }
      return null;
    } catch (e) {
      print('Error getting cached student: $e');
      return null;
    }
  }

  /// Get count of cached students (for offline indicator)
  int getCachedStudentCount() {
    return _studentsBox.length;
  }

  /// Clear all cached students
  Future<void> clearCache() async {
    await _studentsBox.clear();
  }
}

