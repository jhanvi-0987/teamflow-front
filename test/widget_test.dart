import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/authentication/domain/models/user.dart';
import 'package:mobile/features/authentication/domain/repositories/auth_repository.dart';
import 'package:mobile/features/authentication/presentation/providers/auth_providers.dart';
import 'package:mobile/features/authentication/presentation/screens/login_screen.dart';

class FakeAuthRepo implements AuthRepository {
  String? lastLoginEmail;
  String? lastLoginPassword;

  @override
  Future<User> login({required String email, required String password}) async {
    lastLoginEmail = email;
    lastLoginPassword = password;
    return User(
      id: 'mock-1',
      email: email,
      name: 'Tester',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String name,
  }) async =>
      throw UnimplementedError();

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('LoginScreen form validation and submission smoke test', (tester) async {
    final fakeRepo = FakeAuthRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    // Verify initial elements exist
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to your TeamFlow workspace'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);

    // Tap submit with empty inputs
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify validation errors appear
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    // Enter invalid email
    await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
    await tester.enterText(find.byType(TextFormField).last, 'pass');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);

    // Enter valid credentials
    await tester.enterText(find.byType(TextFormField).first, 'developer@teamflow.com');
    await tester.enterText(find.byType(TextFormField).last, 'Password123!');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Verify repository was invoked with valid input
    expect(fakeRepo.lastLoginEmail, 'developer@teamflow.com');
    expect(fakeRepo.lastLoginPassword, 'Password123!');
  });
}
