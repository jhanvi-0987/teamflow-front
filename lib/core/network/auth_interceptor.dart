import 'dart:async';
import 'package:dio/dio.dart';
import '../auth/token_storage.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio;
  final void Function(String newToken)? onTokenRefreshed;
  Completer<String?>? _refreshCompleter;

  AuthInterceptor(this._tokenStorage, this._dio, {this.onTokenRefreshed});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip token for public auth routes
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/register') ||
        options.path.contains('/health')) {
      return handler.next(options);
    }

    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only attempt refresh on 401 Unauthorized for non-auth endpoints
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/login') &&
        !err.requestOptions.path.contains('/auth/refresh')) {
      try {
        final newToken = await _refreshTokenSerialized();
        if (newToken != null) {
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(retryOptions);
          return handler.resolve(response);
        }
      } catch (e) {
        await _tokenStorage.clearTokens();
      }
    }

    return handler.next(err);
  }

  // Serialized refresh lock prevents parallel refresh races
  Future<String?> _refreshTokenSerialized() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final response = await _dio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'skipAuth': true}),
      );

      final newAccessToken = response.data['accessToken'] as String?;
      final newRefreshToken = response.data['refreshToken'] as String?;

      if (newAccessToken != null && newRefreshToken != null) {
        await _tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
        onTokenRefreshed?.call(newAccessToken);
        _refreshCompleter!.complete(newAccessToken);
        return newAccessToken;
      }

      _refreshCompleter!.complete(null);
      return null;
    } catch (e) {
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }
}
