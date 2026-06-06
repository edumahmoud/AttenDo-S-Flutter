import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants/app_constants.dart';
import 'supabase_service.dart';

// ---------------------------------------------------------------------------
// Custom Exceptions
// ---------------------------------------------------------------------------

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => 'ApiException($statusCode $errorCode): $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({String? message})
      : super(message: message ?? 'Unauthorized', statusCode: 401);
}

class ServerException extends ApiException {
  const ServerException({String? message, super.statusCode})
      : super(message: message ?? 'Server error');
}

class NetworkException extends ApiException {
  const NetworkException({String? message})
      : super(message: message ?? 'Network error');
}

class TimeoutException extends ApiException {
  const TimeoutException({String? message})
      : super(message: message ?? 'Request timed out');
}

// ---------------------------------------------------------------------------
// API Service
// ---------------------------------------------------------------------------

class ApiService {
  late final Dio _dio;
  final SupabaseService _supabaseService;

  ApiService(this._supabaseService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_supabaseService),
      _LogInterceptor(),
    ]);
  }

  // ---------------------------------------------------------------------------
  // HTTP Methods
  // ---------------------------------------------------------------------------

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Multipart Upload
  // ---------------------------------------------------------------------------

  Future<Response> uploadFile(
    String path,
    FormData formData, {
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Exception Mapping
  // ---------------------------------------------------------------------------

  ApiException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final body = e.response?.data;
        final message =
            body is Map ? body['message']?.toString() ?? e.message : e.message;
        if (statusCode == 401) {
          return UnauthorizedException(message: message);
        }
        return ServerException(
          message: message ?? 'Server error',
          statusCode: statusCode,
        );
      default:
        return ApiException(message: e.message ?? 'Unknown error');
    }
  }
}

// ---------------------------------------------------------------------------
// Auth Interceptor
// ---------------------------------------------------------------------------

class _AuthInterceptor extends Interceptor {
  final SupabaseService _supabaseService;

  _AuthInterceptor(this._supabaseService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final session = _supabaseService.currentSession;
    if (session != null) {
      // Check if token is about to expire and refresh if needed
      final expiresAt = session.expiresAt;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if ((expiresAt ?? 0) - now < 60) {
        // Less than 1 minute left – refresh
        await _supabaseService.refreshSession();
      }

      final token = _supabaseService.currentSession?.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    options.headers['apikey'] = AppConstants.supabaseAnonKey;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Attempt a single token refresh and retry
      try {
        await _supabaseService.refreshSession();
        final newToken = _supabaseService.currentSession?.accessToken;
        if (newToken != null) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          final response = await Dio().fetch(options);
          return handler.resolve(response);
        }
      } catch (_) {
        // Refresh failed – let the 401 propagate
      }
    }
    handler.next(err);
  }
}

// ---------------------------------------------------------------------------
// Log Interceptor (debug only)
// ---------------------------------------------------------------------------

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // In production, replace with a proper logger
    // debugPrint('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // debugPrint('✗ ${err.type} ${err.requestOptions.uri}');
    handler.next(err);
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(supabaseServiceProvider));
});
