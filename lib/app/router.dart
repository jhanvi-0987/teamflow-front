import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../features/authentication/presentation/controllers/auth_state.dart';
import '../features/authentication/presentation/providers/auth_providers.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/register_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/projects/presentation/screens/project_detail_screen.dart';
import '../features/tasks/presentation/screens/task_detail_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _AuthSplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/projects/:id',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return ProjectDetailScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/tasks/:id',
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return TaskDetailScreen(taskId: taskId);
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isSplash = state.matchedLocation == '/';

      // 1. While auth state is being determined on app launch
      if (authState.status == AuthStatus.initial ||
          (authState.status == AuthStatus.loading && isSplash)) {
        return null; // Keep displaying splash screen
      }

      // 2. If authenticated, route to home from splash or auth pages
      if (authState.status == AuthStatus.authenticated) {
        if (isLoggingIn || isSplash) {
          return '/home';
        }
        return null;
      }

      // 3. If unauthenticated or error, redirect to /login
      if (authState.status == AuthStatus.unauthenticated ||
          authState.status == AuthStatus.error) {
        return isLoggingIn ? null : '/login';
      }

      return null;
    },
  );
});

class _AuthSplashScreen extends StatelessWidget {
  const _AuthSplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.elevatedShadow,
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'TeamFlow',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
