import '../../../../core/auth/token_storage.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
  })  : _remoteDataSource = remoteDataSource,
        _tokenStorage = tokenStorage;

  @override
  Future<User> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final userDto = await _remoteDataSource.register(
      email: email,
      password: password,
      name: name,
    );
    return userDto.toDomain();
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      email: email,
      password: password,
    );

    final accessToken = response['accessToken'] as String;
    final refreshToken = response['refreshToken'] as String;
    final userMap = response['user'] as Map<String, dynamic>;

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return User(
      id: userMap['id'] as String,
      email: userMap['email'] as String,
      name: userMap['name'] as String,
      emailVerifiedAt: userMap['emailVerifiedAt'] != null
          ? DateTime.parse(userMap['emailVerifiedAt'] as String)
          : null,
      createdAt: DateTime.parse(userMap['createdAt'] as String),
    );
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final userDto = await _remoteDataSource.getMe();
      return userDto.toDomain();
    } catch (_) {
      await _tokenStorage.clearTokens();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      await _tokenStorage.clearTokens();
    }
  }
}
