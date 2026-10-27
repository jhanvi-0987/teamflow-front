import 'dart:convert';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/errors/failures.dart';
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
    final user = userDto.toDomain();

    // Cache user profile
    await _tokenStorage.saveUser(jsonEncode({
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'emailVerifiedAt': user.emailVerifiedAt?.toIso8601String(),
      'createdAt': user.createdAt.toIso8601String(),
    }));

    return user;
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

    final user = User(
      id: userMap['id'] as String,
      email: userMap['email'] as String,
      name: userMap['name'] as String,
      emailVerifiedAt: userMap['emailVerifiedAt'] != null
          ? DateTime.parse(userMap['emailVerifiedAt'] as String)
          : null,
      createdAt: DateTime.parse(userMap['createdAt'] as String),
    );

    // Cache user profile for instant offline restore on app restart
    await _tokenStorage.saveUser(jsonEncode({
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'emailVerifiedAt': user.emailVerifiedAt?.toIso8601String(),
      'createdAt': user.createdAt.toIso8601String(),
    }));

    return user;
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    // Attempt to read cached user for immediate restoration
    User? cachedUser;
    final cachedRaw = await _tokenStorage.getUser();
    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        final map = jsonDecode(cachedRaw) as Map<String, dynamic>;
        cachedUser = User(
          id: map['id'] as String,
          email: map['email'] as String,
          name: map['name'] as String,
          emailVerifiedAt: map['emailVerifiedAt'] != null
              ? DateTime.parse(map['emailVerifiedAt'] as String)
              : null,
          createdAt: DateTime.parse(map['createdAt'] as String),
        );
      } catch (_) {}
    }

    try {
      final userDto = await _remoteDataSource.getMe();
      final freshUser = userDto.toDomain();

      // Refresh cache with latest data
      await _tokenStorage.saveUser(jsonEncode({
        'id': freshUser.id,
        'email': freshUser.email,
        'name': freshUser.name,
        'emailVerifiedAt': freshUser.emailVerifiedAt?.toIso8601String(),
        'createdAt': freshUser.createdAt.toIso8601String(),
      }));

      return freshUser;
    } catch (e) {
      // Only wipe stored session if auth was actively rejected (e.g. 401 Unauthorized)
      if (e is AuthFailure || (e is ServerFailure && e.statusCode == 401)) {
        await _tokenStorage.clearTokens();
        return null;
      }

      // If temporary network issue or server starting up, return cached user
      if (cachedUser != null) {
        return cachedUser;
      }

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
