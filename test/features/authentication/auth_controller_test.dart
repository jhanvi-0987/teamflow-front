import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/features/authentication/domain/models/user.dart';
import 'package:mobile/features/authentication/domain/repositories/auth_repository.dart';
import 'package:mobile/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:mobile/features/authentication/presentation/controllers/auth_state.dart';

class MockAuthRepo implements AuthRepository {
  bool failNext = false;
  User? user;

  @override
  Future<User> login({required String email, required String password}) async {
    if (failNext) {
      throw const AuthFailure(code: 'INVALID_CREDENTIALS', message: 'Invalid credentials');
    }
    user = User(
      id: 'mock-id',
      email: email,
      name: 'Mock User',
      createdAt: DateTime.now(),
    );
    return user!;
  }

  @override
  Future<User> register({required String email, required String password, required String name}) async {
    if (failNext) {
      throw const AuthFailure(code: 'EMAIL_ALREADY_EXISTS', message: 'Email taken');
    }
    user = User(
      id: 'mock-id',
      email: email,
      name: name,
      createdAt: DateTime.now(),
    );
    return user!;
  }

  @override
  Future<User?> getCurrentUser() async => user;

  @override
  Future<void> logout() async {
    user = null;
  }
}

void main() {
  group('AuthController (Unit)', () {
    late MockAuthRepo mockRepo;
    late AuthController controller;

    setUp(() {
      mockRepo = MockAuthRepo();
      controller = AuthController(mockRepo);
    });

    test('initial state should be AuthInitial', () {
      expect(controller.state, const AuthState.initial());
    });

    test('login success should transition to AuthLoading then AuthAuthenticated', () async {
      final future = controller.login('alice@example.com', 'password123');
      expect(controller.state, const AuthState.loading());

      await future;
      expect(controller.state.isAuthenticated, isTrue);
      expect(controller.state.user?.email, 'alice@example.com');
    });

    test('login failure should transition to AuthError', () async {
      mockRepo.failNext = true;

      await controller.login('wrong@example.com', 'wrong');
      expect(controller.state.isError, isTrue);
      expect(controller.state.errorMessage, 'Invalid credentials');
    });

    test('logout should transition back to AuthUnauthenticated', () async {
      await controller.login('alice@example.com', 'password123');
      expect(controller.state.isAuthenticated, isTrue);

      await controller.logout();
      expect(controller.state.isUnauthenticated, isTrue);
    });
  });
}
