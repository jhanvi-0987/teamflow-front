import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_dto.dart';

abstract class AuthRemoteDataSource {
  Future<UserDto> register({
    required String email,
    required String password,
    required String name,
  });

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  Future<UserDto> getMe();

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<UserDto> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.register,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
          'name': name.trim(),
        },
      );
      return UserDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.login,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserDto> getMe() async {
    try {
      final response = await dio.get(ApiEndpoints.me);
      return UserDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Failure _handleDioError(DioException error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final data = error.response!.data as Map<String, dynamic>;
      final errObj = data['error'] as Map<String, dynamic>?;
      if (errObj != null) {
        return AuthFailure(
          message: errObj['message']?.toString() ?? 'Authentication error',
          code: errObj['code']?.toString(),
        );
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    return ServerFailure(
      message: error.message ?? 'Server error occurred',
      statusCode: error.response?.statusCode,
    );
  }
}
