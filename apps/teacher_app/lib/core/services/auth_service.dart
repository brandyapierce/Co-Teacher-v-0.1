import 'package:dio/dio.dart';
import '../network/api_client.dart';
import 'token_storage_service.dart';

/// Authentication service that handles login, logout, and token management
/// 
/// This is the main authentication service that:
/// - Handles login/logout
/// - Manages JWT tokens
/// - Provides authentication state
/// - Handles token refresh
/// 
/// EDUCATIONAL NOTE:
/// This is a "Repository" in Clean Architecture:
/// - Presentation layer (UI) calls this service
/// - This service calls API client (data source)
/// - Handles business logic (store tokens, check auth state)
class AuthService {
  final ApiClient _apiClient;
  final TokenStorageService _tokenStorage;

  AuthService({
    required ApiClient apiClient,
    required TokenStorageService tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  // ==================== AUTHENTICATION ====================

  /// Login with email and password
  /// 
  /// Returns true if login successful, false otherwise
  /// On success, stores JWT tokens securely
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.login(
        email: email,
        password: password,
      );

      if (response.statusCode == 200) {
        // Extract tokens from response
        final data = response.data;
        final accessToken = data['access_token'] as String;
        // Backend doesn't send refresh_token yet, so we'll reuse access_token for now
        final refreshToken = data['refresh_token'] as String? ?? accessToken;
        // Backend sends teacher_id instead of user_id
        final userId = (data['teacher_id'] ?? data['user_id']) as String;
        // Backend doesn't send email in login response, use the login email
        final userEmail = data['email'] as String? ?? email;

        // Store tokens securely
        await _tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        // Store user info
        await _tokenStorage.saveUserInfo(
          userId: userId,
          email: userEmail,
        );

        return AuthResult(
          success: true,
          message: 'Login successful',
          userId: userId,
          email: userEmail,
        );
      }

      return AuthResult(
        success: false,
        message: 'Login failed: ${response.statusMessage}',
      );
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        message: _handleDioError(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Logout and clear tokens
  Future<void> logout() async {
    try {
      // Call logout endpoint to invalidate token on server
      await _apiClient.logout();
    } catch (e) {
      // Even if API call fails, we still clear local tokens
      // (user might be offline)
    } finally {
      // Always clear local tokens
      await _tokenStorage.clearTokens();
    }
  }

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    return await _tokenStorage.isAuthenticated();
  }

  /// Get current user info from API
  /// 
  /// This refreshes the user data from the backend
  Future<UserInfo?> getCurrentUser() async {
    try {
      final response = await _apiClient.getCurrentUser();

      if (response.statusCode == 200) {
        final data = response.data;
        return UserInfo(
          id: data['id'] as String,
          email: data['email'] as String,
          firstName: data['first_name'] as String?,
          lastName: data['last_name'] as String?,
          role: data['role'] as String?,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get cached user ID
  Future<String?> getCachedUserId() async {
    return await _tokenStorage.getUserId();
  }

  /// Get cached user email
  Future<String?> getCachedUserEmail() async {
    return await _tokenStorage.getUserEmail();
  }

  // ==================== ERROR HANDLING ====================

  /// Convert DioException to user-friendly message
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout - please check your internet connection';
      
      case DioExceptionType.sendTimeout:
        return 'Request timeout - server is not responding';
      
      case DioExceptionType.receiveTimeout:
        return 'Server response timeout';
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? e.response?.data?['detail'];
        
        if (statusCode == 401) {
          return message ?? 'Invalid email or password';
        } else if (statusCode == 403) {
          return 'Access forbidden - insufficient permissions';
        } else if (statusCode == 404) {
          return 'Endpoint not found - please update the app';
        } else if (statusCode == 500) {
          return 'Server error - please try again later';
        }
        
        return message ?? 'Request failed with status $statusCode';
      
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      
      case DioExceptionType.connectionError:
        return 'No internet connection';
      
      default:
        return 'An unexpected error occurred: ${e.message}';
    }
  }
}

// ==================== RESULT CLASSES ====================

/// Result of authentication operation
class AuthResult {
  final bool success;
  final String message;
  final String? userId;
  final String? email;

  AuthResult({
    required this.success,
    required this.message,
    this.userId,
    this.email,
  });
}

/// User information
class UserInfo {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? role;

  UserInfo({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.role,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return email;
  }
}

