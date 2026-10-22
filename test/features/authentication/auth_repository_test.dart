import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/features/authentication/domain/models/user.dart';
import 'package:mobile/features/authentication/domain/repositories/auth_repository.dart';

// Test implementation of AuthRepository to verify interface contracts
class MockAuthRepository implements AuthRepository {
  bool shouldFail = false;
  User? currentUser;

  @override
  Future<User> register({
    required String email,
    required String password,
    required String name,
  }) async {
    if (shouldFail) {
      throw const AuthFailure(code: 'EMAIL_ALREADY_EXISTS', message: 'Email already exists');
    }
    final user = User(
      id: 'uuid-1',
      email: email.trim().toLowerCase(),
      name: name,
      createdAt: DateTime.now(),
    );
    currentUser = user;
    return user;
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      throw const AuthFailure(code: 'INVALID_CREDENTIALS', message: 'Invalid credentials');
    }
    final user = User(
      id: 'uuid-1',
      email: email.trim().toLowerCase(),
      name: 'Test User',
      createdAt: DateTime.now(),
    );
    currentUser = user;
    return user;
  }

  @override
  Future<User?> getCurrentUser() async {
    return currentUser;
  }

  @override
  Future<void> logout() async {
    currentUser = null;
  }
}

void main() {
  group('AuthRepository Contract (Unit)', () {
    late MockAuthRepository repository;

    setUp(() {
      repository = MockAuthRepository();
    });

    test('register should return User with normalized email', () async {
      final user = await repository.register(
        email: '  Alice@Domain.COM ',
        password: 'Password123!',
        name: 'Alice',
      );

      expect(user.email, 'alice@domain.com');
      expect(user.name, 'Alice');
      expect(repository.currentUser, isNotNull);
    });

    test('register should throw AuthFailure when server rejects', () async {
      repository.shouldFail = true;

      expect(
        () => repository.register(
          email: 'duplicate@domain.com',
          password: 'Password123!',
          name: 'Alice',
        ),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('login should authenticate and store session', () async {
      final user = await repository.login(
        email: 'alice@domain.com',
        password: 'Password123!',
      );

      expect(user.email, 'alice@domain.com');
      expect(repository.currentUser, isNotNull);
    });

    test('logout should clear currentUser session', () async {
      await repository.login(
        email: 'alice@domain.com',
        password: 'Password123!',
      );
      expect(repository.currentUser, isNotNull);

      await repository.logout();
      expect(repository.currentUser, isNull);
    });
  });
}
