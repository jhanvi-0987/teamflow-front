import 'package:dio/dio.dart';
import '../auth/token_storage.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio dio;

  ApiClient({
    Dio? customDio,
    TokenStorage? tokenStorage,
    void Function(String)? onTokenRefreshed,
  })  : dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    if (tokenStorage != null) {
      dio.interceptors.add(
        AuthInterceptor(tokenStorage, dio, onTokenRefreshed: onTokenRefreshed),
      );
    }
  }
}
