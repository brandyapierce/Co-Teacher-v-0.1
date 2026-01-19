import 'package:hive/hive.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';
import '../models/class_model.dart';
import '../../../../core/network/api_client.dart';

/// =============================================================================
/// CLASS REPOSITORY - Data access layer for classes
/// =============================================================================
/// 
/// LEARNING GUIDE: Repository Pattern
/// 
/// WHAT IS A REPOSITORY?
/// A repository is a class that handles all data operations for a specific 
/// type of data (in this case, classes). It:
/// - Abstracts the data source (API, local database, or both)
/// - Provides a clean API for the business logic layer
/// - Handles caching and offline support
/// 
/// OFFLINE-FIRST STRATEGY:
/// 1. Read: Try local cache first (fast), then sync with server
/// 2. Write: Save locally immediately, then sync to server
/// 3. This ensures the app works without internet
/// =============================================================================

class ClassRepository {
  final Box<ClassModel> _classBox;
  final ApiClient _apiClient;

  ClassRepository({
    Box<ClassModel>? classBox,
    ApiClient? apiClient,
  })  : _classBox = classBox ?? GetIt.instance<Box<ClassModel>>(),
        _apiClient = apiClient ?? GetIt.instance<ApiClient>();

  // ==========================================================================
  // READ OPERATIONS
  // ==========================================================================

  /// Get all classes for a teacher
  /// 
  /// STRATEGY: Cache-first with background refresh
  /// 1. Return cached data immediately
  /// 2. Fetch from server in background
  /// 3. Update cache with fresh data
  Future<List<ClassModel>> getClasses({
    required String teacherId,
    bool forceRefresh = false,
  }) async {
    // Return cache first for instant display
    if (!forceRefresh && _classBox.isNotEmpty) {
      final cached = _classBox.values
          .where((c) => c.teacherId == teacherId && c.isActive)
          .toList();
      if (cached.isNotEmpty) {
        // Trigger background refresh
        _refreshFromServer(teacherId);
        return cached;
      }
    }

    // Fetch from server
    try {
      final response = await _apiClient.getClasses(teacherId: teacherId);
      final classes = (response as List)
          .map((json) => ClassModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update cache
      await _updateCache(classes);
      return classes;
    } catch (e) {
      // If server fails, return cache
      final cached = _classBox.values
          .where((c) => c.teacherId == teacherId && c.isActive)
          .toList();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  /// Get a single class by ID
  Future<ClassModel?> getClassById(String classId) async {
    // Check cache first
    if (_classBox.containsKey(classId)) {
      return _classBox.get(classId);
    }

    // Fetch from server
    try {
      final response = await _apiClient.getClassById(classId);
      final classModel = ClassModel.fromJson(response as Map<String, dynamic>);
      
      // Update cache
      await _classBox.put(classId, classModel);
      return classModel;
    } catch (e) {
      return null;
    }
  }

  /// Get all students in a class
  Future<List<String>> getClassStudentIds(String classId) async {
    final classModel = await getClassById(classId);
    return classModel?.studentIds ?? [];
  }

  // ==========================================================================
  // WRITE OPERATIONS
  // ==========================================================================

  /// Create a new class
  /// 
  /// LEARNING: Optimistic updates
  /// We save locally first (optimistic), then sync to server.
  /// If server fails, data is still saved locally.
  Future<ClassModel> createClass({
    required String name,
    required String teacherId,
    String? gradeLevel,
    String? subject,
    String? room,
    String? academicYear,
    String? color,
  }) async {
    // Generate ID locally
    final id = const Uuid().v4();
    
    final newClass = ClassModel(
      id: id,
      name: name,
      teacherId: teacherId,
      gradeLevel: gradeLevel,
      subject: subject,
      room: room,
      academicYear: academicYear,
      color: color,
    );

    // Save locally first (optimistic)
    await _classBox.put(id, newClass);

    // Sync to server
    try {
      await _apiClient.createClass(newClass.toJson());
    } catch (e) {
      // Server sync failed, but local save succeeded
      // Could implement retry queue here
      print('Class sync failed, will retry later: $e');
    }

    return newClass;
  }

  /// Update an existing class
  Future<ClassModel> updateClass(ClassModel classModel) async {
    final updated = classModel.copyWith(updatedAt: DateTime.now());
    
    // Save locally
    await _classBox.put(classModel.id, updated);

    // Sync to server
    try {
      await _apiClient.updateClass(classModel.id, updated.toJson());
    } catch (e) {
      print('Class update sync failed: $e');
    }

    return updated;
  }

  /// Delete a class (soft delete - marks as inactive)
  Future<void> deleteClass(String classId) async {
    final classModel = _classBox.get(classId);
    if (classModel != null) {
      // Soft delete locally
      await _classBox.put(classId, classModel.copyWith(isActive: false));

      // Sync to server
      try {
        await _apiClient.deleteClass(classId);
      } catch (e) {
        print('Class delete sync failed: $e');
      }
    }
  }

  // ==========================================================================
  // STUDENT MANAGEMENT
  // ==========================================================================

  /// Add a student to a class
  Future<ClassModel?> addStudentToClass(String classId, String studentId) async {
    final classModel = _classBox.get(classId);
    if (classModel == null) return null;

    if (classModel.studentIds.contains(studentId)) {
      return classModel; // Already enrolled
    }

    final updated = classModel.copyWith(
      studentIds: [...classModel.studentIds, studentId],
    );

    await _classBox.put(classId, updated);

    // Sync to server
    try {
      await _apiClient.addStudentToClass(classId, studentId);
    } catch (e) {
      print('Add student sync failed: $e');
    }

    return updated;
  }

  /// Remove a student from a class
  Future<ClassModel?> removeStudentFromClass(String classId, String studentId) async {
    final classModel = _classBox.get(classId);
    if (classModel == null) return null;

    final updated = classModel.copyWith(
      studentIds: classModel.studentIds.where((id) => id != studentId).toList(),
    );

    await _classBox.put(classId, updated);

    // Sync to server
    try {
      await _apiClient.removeStudentFromClass(classId, studentId);
    } catch (e) {
      print('Remove student sync failed: $e');
    }

    return updated;
  }

  /// Add multiple students to a class
  Future<ClassModel?> addStudentsToClass(String classId, List<String> studentIds) async {
    final classModel = _classBox.get(classId);
    if (classModel == null) return null;

    final newStudentIds = studentIds.where(
      (id) => !classModel.studentIds.contains(id),
    ).toList();

    if (newStudentIds.isEmpty) return classModel;

    final updated = classModel.copyWith(
      studentIds: [...classModel.studentIds, ...newStudentIds],
    );

    await _classBox.put(classId, updated);

    // Sync to server (batch operation)
    try {
      for (final studentId in newStudentIds) {
        await _apiClient.addStudentToClass(classId, studentId);
      }
    } catch (e) {
      print('Batch add students sync failed: $e');
    }

    return updated;
  }

  // ==========================================================================
  // CACHE MANAGEMENT
  // ==========================================================================

  /// Refresh data from server in background
  Future<void> _refreshFromServer(String teacherId) async {
    try {
      final response = await _apiClient.getClasses(teacherId: teacherId);
      final classes = (response as List)
          .map((json) => ClassModel.fromJson(json as Map<String, dynamic>))
          .toList();
      await _updateCache(classes);
    } catch (e) {
      // Silent failure - cache remains unchanged
    }
  }

  /// Update local cache with server data
  Future<void> _updateCache(List<ClassModel> classes) async {
    for (final classModel in classes) {
      await _classBox.put(classModel.id, classModel);
    }
  }

  /// Clear all cached classes
  Future<void> clearCache() async {
    await _classBox.clear();
  }

  /// Get count of classes for a teacher
  int getClassCount(String teacherId) {
    return _classBox.values
        .where((c) => c.teacherId == teacherId && c.isActive)
        .length;
  }
}
