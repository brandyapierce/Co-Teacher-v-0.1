import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Interceptor that logs all HTTP requests and responses
/// 
/// This is super useful for debugging API issues:
/// - See what requests are being sent
/// - Check response data and status codes
/// - Identify slow requests (timing)
/// - Debug errors
/// 
/// EDUCATIONAL NOTE:
/// Only logs in debug mode to avoid performance issues in production.
/// Uses dart:developer instead of print() for better performance.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppConfig.isDebug) {
      developer.log(
        '📤 REQUEST [${options.method}] ${options.uri}',
        name: 'API',
      );
      
      // Log headers (except sensitive Authorization)
      final headers = Map<String, dynamic>.from(options.headers);
      if (headers.containsKey('Authorization')) {
        headers['Authorization'] = '[REDACTED]'; // Don't log tokens!
      }
      developer.log('Headers: $headers', name: 'API');
      
      // Log request body if present
      if (options.data != null) {
        developer.log('Body: ${options.data}', name: 'API');
      }
    }
    
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (AppConfig.isDebug) {
      developer.log(
        '📥 RESPONSE [${response.statusCode}] ${response.requestOptions.uri}',
        name: 'API',
      );
      developer.log('Data: ${response.data}', name: 'API');
    }
    
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (AppConfig.isDebug) {
      developer.log(
        '❌ ERROR [${err.response?.statusCode ?? 'NO STATUS'}] ${err.requestOptions.uri}',
        name: 'API',
        error: err.message,
      );
      
      if (err.response?.data != null) {
        developer.log('Error Data: ${err.response?.data}', name: 'API');
      }
    }
    
    handler.next(err);
  }
}

