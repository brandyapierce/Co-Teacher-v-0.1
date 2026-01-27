/// Custom exception class for application errors
/// 
/// EDUCATIONAL NOTE - Custom Exceptions:
/// Creating custom exception classes helps with:
/// 1. Clear error handling - you can catch specific types
/// 2. Better error messages - add context and user-friendly text
/// 3. Debugging - stack traces lead to where the error originated
/// 4. Separation of concerns - different exceptions for different layers
/// 
/// Example usage:
/// ```dart
/// try {
///   // Some API call
/// } on AppException catch (e) {
///   // Handle known app errors with user-friendly messages
///   showErrorToUser(e.message);
/// } on DioException catch (e) {
///   // Handle network errors
///   showNetworkError();
/// } catch (e) {
///   // Handle unexpected errors
///   logUnexpectedError(e);
/// }
/// ```
class AppException implements Exception {
  /// The error message to display to the user or developer
  final String message;
  
  /// Optional: HTTP status code if this is a network error
  final int? statusCode;
  
  /// Optional: The underlying error that caused this exception
  final dynamic originalError;

  AppException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'AppException: $message (Status: $statusCode)';
    }
    return 'AppException: $message';
  }
}

/// Exception thrown when authentication fails
class AuthException extends AppException {
  AuthException(super.message);
}

/// Exception thrown when a network request fails
class NetworkException extends AppException {
  NetworkException(super.message, {super.statusCode});
}

/// Exception thrown when data validation fails
class ValidationException extends AppException {
  ValidationException(super.message);
}

/// Exception thrown when a resource is not found
class NotFoundException extends AppException {
  NotFoundException(super.message) : super(statusCode: 404);
}

