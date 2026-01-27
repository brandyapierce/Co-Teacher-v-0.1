import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/class_model.dart';

/// Class API Service
/// 
/// Handles all class-related API calls to the backend.
/// This service sits between the UI (Cubit) and the network layer (ApiClient).
/// 
/// EDUCATIONAL NOTE - Service Layer:
/// The service layer translates between the API format and our app's format:
/// - API returns JSON → Service converts to ClassModel objects
/// - Handles errors gracefully
/// - Provides a clean interface for the business logic layer
class ClassApiService {
  final ApiClient _apiClient;

  ClassApiService(this._apiClient);

  /// Fetch all classes for the current teacher from the backend
  /// 
  /// Returns a list of ClassModel objects
  /// Throws DioException if network request fails
  Future<List<ClassModel>> getClasses({
    String? teacherId,
  }) async {
    try {
      final response = await _apiClient.getClasses(teacherId: teacherId);

      if (response.statusCode == 200) {
        // Backend returns a list of class JSON objects
        final data = response.data;
        
        // Handle different response formats
        List<dynamic> classesJson;
        if (data is List) {
          classesJson = data;
        } else if (data is Map && data.containsKey('classes')) {
          classesJson = data['classes'] as List<dynamic>;
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: 'Unexpected response format',
          );
        }
        
        // Convert each JSON object to a ClassModel
        return classesJson
            .map((json) => ClassModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load classes: ${response.statusCode}',
      );
    } catch (e) {
      // Re-throw for the caller to handle
      rethrow;
    }
  }

  /// Fetch a single class by ID
  Future<ClassModel> getClass(String classId) async {
    try {
      final response = await _apiClient.getClassById(classId);

      if (response.statusCode == 200) {
        return ClassModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load class: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new class
  Future<ClassModel> createClass(ClassModel classModel) async {
    try {
      final response = await _apiClient.createClass(classModel.toJson());

      if (response.statusCode == 201) {
        return ClassModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to create class: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing class
  Future<ClassModel> updateClass(String classId, ClassModel classModel) async {
    try {
      final response = await _apiClient.updateClass(classId, classModel.toJson());

      if (response.statusCode == 200) {
        return ClassModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to update class: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a class
  Future<void> deleteClass(String classId) async {
    try {
      final response = await _apiClient.deleteClass(classId);

      if (response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to delete class: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Enroll a student in a class
  Future<void> enrollStudent(String classId, String studentId) async {
    try {
      final response = await _apiClient.enrollStudentInClass(
        classId,
        {'student_id': studentId},
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to enroll student: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Remove a student from a class
  Future<void> removeStudent(String classId, String studentId) async {
    try {
      final response = await _apiClient.removeStudentFromClass(classId, studentId);

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to remove student: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
