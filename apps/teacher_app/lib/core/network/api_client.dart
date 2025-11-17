import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';

/// API Client for making HTTP requests to the backend
/// 
/// This is the central networking class that handles:
/// - Base URL configuration
/// - Request/response interceptors
/// - Common headers
/// - Timeout configuration
/// 
/// EDUCATIONAL NOTE:
/// Dio is like a supercharged version of http package:
/// - Interceptors: Modify requests/responses automatically
/// - Timeout handling: Cancel slow requests
/// - Error handling: Unified error responses
/// - Request cancellation: Cancel ongoing requests
class ApiClient {
  late final Dio _dio;

  ApiClient({
    String? baseUrl,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors in order (they execute in order added)
    _dio.interceptors.addAll([
      LoggingInterceptor(), // Log all requests/responses (for debugging)
      AuthInterceptor(), // Add JWT token to requests automatically
    ]);
  }

  /// Expose the underlying Dio instance for advanced usage
  Dio get dio => _dio;

  // ==================== AUTHENTICATION ENDPOINTS ====================

  /// POST /api/v1/auth/login
  /// Login with email and password
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await _dio.post(
      '/api/v1/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  /// POST /api/v1/auth/logout
  /// Logout and invalidate token
  Future<Response> logout() async {
    return await _dio.post('/api/v1/auth/logout');
  }

  /// POST /api/v1/auth/refresh
  /// Refresh JWT token when it expires
  Future<Response> refreshToken({required String refreshToken}) async {
    return await _dio.post(
      '/api/v1/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
  }

  /// GET /api/v1/auth/me
  /// Get current authenticated user info
  Future<Response> getCurrentUser() async {
    return await _dio.get('/api/v1/auth/me');
  }

  // ==================== STUDENT ROSTER ENDPOINTS ====================

  /// GET /api/v1/students
  /// Get list of students (can be filtered by class)
  Future<Response> getStudents({
    String? classId,
    int? page,
    int? limit,
  }) async {
    return await _dio.get(
      '/api/v1/students',
      queryParameters: {
        if (classId != null) 'class_id': classId,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    );
  }

  /// GET /api/v1/students/{id}
  /// Get a single student by ID
  Future<Response> getStudent(String studentId) async {
    return await _dio.get('/api/v1/students/$studentId');
  }

  /// POST /api/v1/students
  /// Create a new student
  Future<Response> createStudent(Map<String, dynamic> studentData) async {
    return await _dio.post('/api/v1/students', data: studentData);
  }

  /// PUT /api/v1/students/{id}
  /// Update student information
  Future<Response> updateStudent(
    String studentId,
    Map<String, dynamic> studentData,
  ) async {
    return await _dio.put('/api/v1/students/$studentId', data: studentData);
  }

  // ==================== ATTENDANCE ENDPOINTS ====================

  /// POST /api/v1/attendance
  /// Submit attendance record
  Future<Response> createAttendance(Map<String, dynamic> attendanceData) async {
    return await _dio.post('/api/v1/attendance', data: attendanceData);
  }

  /// POST /api/v1/attendance/batch
  /// Submit multiple attendance records at once
  Future<Response> createAttendanceBatch(
    List<Map<String, dynamic>> attendanceList,
  ) async {
    return await _dio.post(
      '/api/v1/attendance/batch',
      data: {'records': attendanceList},
    );
  }

  /// GET /api/v1/attendance
  /// Get attendance records with filters
  Future<Response> getAttendance({
    String? classId,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) async {
    return await _dio.get(
      '/api/v1/attendance',
      queryParameters: {
        if (classId != null) 'class_id': classId,
        if (studentId != null) 'student_id': studentId,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    );
  }

  /// PUT /api/v1/attendance/{id}
  /// Update attendance record
  Future<Response> updateAttendance(
    String attendanceId,
    Map<String, dynamic> attendanceData,
  ) async {
    return await _dio.put(
      '/api/v1/attendance/$attendanceId',
      data: attendanceData,
    );
  }

  /// DELETE /api/v1/attendance/{id}
  /// Delete attendance record
  Future<Response> deleteAttendance(String attendanceId) async {
    return await _dio.delete('/api/v1/attendance/$attendanceId');
  }

  /// DELETE /api/v1/students/{id}
  /// Delete student
  Future<Response> deleteStudent(String studentId) async {
    return await _dio.delete('/api/v1/students/$studentId');
  }

  // ==================== CLASS ENDPOINTS ====================

  /// GET /api/v1/classes
  /// Get list of classes for the current teacher
  Future<Response> getClasses() async {
    return await _dio.get('/api/v1/classes');
  }

  /// GET /api/v1/classes/{id}
  /// Get class details including student roster
  Future<Response> getClass(String classId) async {
    return await _dio.get('/api/v1/classes/$classId');
  }

  // ==================== HEALTH CHECK ====================

  /// GET /health
  /// Check if backend is reachable
  Future<Response> healthCheck() async {
    return await _dio.get('/health');
  }
}

