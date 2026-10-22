import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/workspaces_remote_data_source.dart';
import '../../data/repositories/workspaces_repository_impl.dart';
import '../../domain/models/workspace.dart';
import '../../domain/models/workspace_member.dart';
import '../../domain/models/invitation.dart';
import '../../domain/repositories/workspaces_repository.dart';
import '../controllers/workspace_controller.dart';
import '../controllers/workspace_state.dart';

final workspacesRemoteDataSourceProvider =
    Provider<WorkspacesRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkspacesRemoteDataSourceImpl(apiClient.dio);
});

final workspacesRepositoryProvider = Provider<WorkspacesRepository>((ref) {
  final remote = ref.watch(workspacesRemoteDataSourceProvider);
  return WorkspacesRepositoryImpl(remote);
});

final workspaceControllerProvider =
    StateNotifierProvider<WorkspaceController, WorkspaceState>((ref) {
  final repo = ref.watch(workspacesRepositoryProvider);
  return WorkspaceController(repo);
});

final currentWorkspaceProvider = Provider<Workspace?>((ref) {
  return ref.watch(workspaceControllerProvider).currentWorkspace;
});

final workspaceMembersProvider =
    FutureProvider.family<List<WorkspaceMember>, String>((ref, workspaceId) async {
  final repo = ref.watch(workspacesRepositoryProvider);
  return repo.getMembers(workspaceId);
});

final workspaceInvitationsProvider =
    FutureProvider.family<List<Invitation>, String>((ref, workspaceId) async {
  final repo = ref.watch(workspacesRepositoryProvider);
  return repo.getPendingInvitations(workspaceId);
});
