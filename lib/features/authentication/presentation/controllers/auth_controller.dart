import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState.initial());

  Future<void> checkAuthStatus() async {
    try {
      final user = await _repository.getCurrentUser();
      if (!mounted) return;
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      if (!mounted) return;
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final user = await _repository.login(email: email, password: password);
      if (!mounted) return;
      state = AuthState.authenticated(user);
    } on Failure catch (e) {
      if (!mounted) return;
      state = AuthState.error(e.message);
    } catch (e) {
      if (!mounted) return;
      state = AuthState.error(e.toString());
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = const AuthState.loading();
    try {
      final user = await _repository.register(
        email: email,
        password: password,
        name: name,
      );
      if (!mounted) return;
      state = AuthState.authenticated(user);
    } on Failure catch (e) {
      if (!mounted) return;
      state = AuthState.error(e.message);
    } catch (e) {
      if (!mounted) return;
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    state = const AuthState.loading();
    try {
      await _repository.logout();
    } finally {
      if (mounted) {
        state = const AuthState.unauthenticated();
      }
    }
  }
}
