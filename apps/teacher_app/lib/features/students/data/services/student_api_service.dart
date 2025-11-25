import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/data/models/student.dart';

/// Student API Service
/// 
/// Handles all student-related API calls to the backend.
/// This service sits between the UI (Cubit) and the network layer (ApiClient).
/// 
/// EDUCATIONAL NOTE - Service Layer:
/// The service layer translates between the API format and our app's format:
/// - API returns JSON → Service converts to Student objects
/// - Handles errors gracefully
/// - Provides a clean interface for the business logic layer
class StudentApiService {
  final ApiClient _apiClient;

  StudentApiService(this._apiClient);

  /// Fetch all students from the backend
  /// 
  /// Returns a list of Student objects
  /// Throws DioException if network request fails
  Future<List<Student>> getStudents({
    String? classId,
  }) async {
    try {
      final response = await _apiClient.getStudents(classId: classId);

      if (response.statusCode == 200) {
        // Backend returns a list of student JSON objects
        final List<dynamic> studentsJson = response.data as List<dynamic>;
        
        // Convert each JSON object to a Student model
        return studentsJson
            .map((json) => Student.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load students: ${response.statusCode}',
      );
    } catch (e) {
      // Re-throw for the caller to handle
      rethrow;
    }
  }

  /// Fetch a single student by ID
  Future<Student> getStudent(String studentId) async {
    try {
      final response = await _apiClient.getStudent(studentId);

      if (response.statusCode == 200) {
        return Student.fromJson(response.data as Map<String, dynamic>);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load student: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new student
  Future<Student> createStudent(Student student) async {
    try {
      final response = await _apiClient.createStudent(student.toJson());

      if (response.statusCode == 201) {
        return Student.fromJson(response.data as Map<String, dynamic>);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to create student: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing student
  Future<Student> updateStudent(String studentId, Student student) async {
    try {
      final response = await _apiClient.updateStudent(studentId, student.toJson());

      if (response.statusCode == 200) {
        return Student.fromJson(response.data as Map<String, dynamic>);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to update student: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a student
  Future<void> deleteStudent(String studentId) async {
    try {
      final response = await _apiClient.deleteStudent(studentId);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to delete student: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

