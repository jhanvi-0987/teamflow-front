import '../models/user.dart';

abstract class AuthRepository {
  Future<User> register({
    required String email,
    required String password,
    required String name,
  });

  Future<User> login({
    required String email,
    required String password,
  });

  Future<User?> getCurrentUser();

  Future<void> logout();
}
