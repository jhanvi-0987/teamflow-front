import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(
    tokenStorage: tokenStorage,
    onTokenRefreshed: (newToken) {
      ref.read(socketServiceProvider).renewAuth(newToken);
    },
  );
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient.dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    tokenStorage: tokenStorage,
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final controller = AuthController(repository);
  controller.checkAuthStatus();
  return controller;
});
