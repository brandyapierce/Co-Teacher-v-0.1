import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../services/token_storage_service.dart';

/// Interceptor that automatically adds JWT token to requests
/// 
/// This interceptor runs BEFORE every HTTP request and:
/// 1. Checks if we have a stored JWT token
/// 2. If yes, adds it to the Authorization header
/// 3. If the request fails with 401 (Unauthorized), tries to refresh the token
/// 
/// EDUCATIONAL NOTE:
/// Interceptors are like middleware in backend frameworks:
/// - onRequest: Runs before sending request (add auth header)
/// - onResponse: Runs after receiving response (log, transform)
/// - onError: Runs when request fails (handle 401, retry)
class AuthInterceptor extends Interceptor {
  final TokenStorageService _tokenStorage = GetIt.instance<TokenStorageService>();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip adding token for auth endpoints (login, register)
    if (_shouldSkipToken(options.path)) {
      return handler.next(options);
    }

    // Get stored access token
    final token = await _tokenStorage.getAccessToken();

    if (token != null) {
      // Add JWT token to Authorization header
      // Format: "Bearer eyJhbGc..."
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Continue with the request
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Check if error is 401 Unauthorized
    if (err.response?.statusCode == 401) {
      // Token might be expired, try to refresh it
      final refreshSuccess = await _attemptTokenRefresh();

      if (refreshSuccess) {
        // Retry the original request with new token
        try {
          final retryResponse = await _retryRequest(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (e) {
          // If retry also fails, pass the error along
          return handler.next(err);
        }
      }
    }

    // For all other errors, pass them along
    handler.next(err);
  }

  /// Check if the endpoint should skip token authentication
  bool _shouldSkipToken(String path) {
    final skipPaths = [
      '/api/v1/auth/login',
      '/api/v1/auth/register',
      '/api/v1/auth/refresh',
      '/health',
    ];

    return skipPaths.any((skipPath) => path.contains(skipPath));
  }

  /// Attempt to refresh the access token using refresh token
  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      
      if (refreshToken == null) {
        // No refresh token available, user needs to login again
        await _tokenStorage.clearTokens();
        return false;
      }

      // Create a new Dio instance to avoid interceptor loops
      final dio = Dio();
      final response = await dio.post(
        '${GetIt.instance<Dio>().options.baseUrl}/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        // Save new tokens
        final newAccessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];
        
        await _tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        return true;
      }

      return false;
    } catch (e) {
      // Refresh failed, clear tokens
      await _tokenStorage.clearTokens();
      return false;
    }
  }

  /// Retry the failed request with new token
  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final token = await _tokenStorage.getAccessToken();
    
    // Update the Authorization header
    if (token != null) {
      requestOptions.headers['Authorization'] = 'Bearer $token';
    }

    // Create a new Dio instance to avoid interceptor loops
    final dio = Dio();
    dio.options = requestOptions.copyWith() as BaseOptions;
    
    return await dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
      ),
    );
  }
}

