import '../../domain/models/workspace.dart';
import '../../domain/models/workspace_member.dart';
import '../../domain/models/invitation.dart';
import '../../domain/repositories/workspaces_repository.dart';
import '../datasources/workspaces_remote_data_source.dart';

class WorkspacesRepositoryImpl implements WorkspacesRepository {
  final WorkspacesRemoteDataSource remoteDataSource;

  WorkspacesRepositoryImpl(this.remoteDataSource);

  @override
  Future<Workspace> createWorkspace({required String name, String? slug}) {
    return remoteDataSource.createWorkspace(name: name, slug: slug);
  }

  @override
  Future<List<Workspace>> getUserWorkspaces() {
    return remoteDataSource.getUserWorkspaces();
  }

  @override
  Future<Workspace> getWorkspaceById(String id) {
    return remoteDataSource.getWorkspaceById(id);
  }

  @override
  Future<Workspace> updateWorkspace(String id, {String? name, String? slug}) {
    return remoteDataSource.updateWorkspace(id, name: name, slug: slug);
  }

  @override
  Future<void> archiveWorkspace(String id) {
    return remoteDataSource.archiveWorkspace(id);
  }

  @override
  Future<void> transferOwnership(String workspaceId, String newOwnerId) {
    return remoteDataSource.transferOwnership(workspaceId, newOwnerId);
  }

  @override
  Future<void> leaveWorkspace(String workspaceId) {
    return remoteDataSource.leaveWorkspace(workspaceId);
  }

  @override
  Future<List<WorkspaceMember>> getMembers(String workspaceId, {String? query}) {
    return remoteDataSource.getMembers(workspaceId, query: query);
  }

  @override
  Future<WorkspaceMember> updateMemberRole(
    String workspaceId,
    String userId,
    WorkspaceRole role,
  ) {
    return remoteDataSource.updateMemberRole(workspaceId, userId, role);
  }

  @override
  Future<void> removeMember(String workspaceId, String userId) {
    return remoteDataSource.removeMember(workspaceId, userId);
  }

  @override
  Future<Invitation> inviteMember(
    String workspaceId,
    String email,
    WorkspaceRole role,
  ) {
    return remoteDataSource.inviteMember(workspaceId, email, role);
  }

  @override
  Future<List<Invitation>> getPendingInvitations(String workspaceId) {
    return remoteDataSource.getPendingInvitations(workspaceId);
  }

  @override
  Future<void> revokeInvitation(String workspaceId, String invitationId) {
    return remoteDataSource.revokeInvitation(workspaceId, invitationId);
  }

  @override
  Future<Workspace> acceptInvitation(String token) {
    return remoteDataSource.acceptInvitation(token);
  }

  @override
  Future<void> declineInvitation(String token) {
    return remoteDataSource.declineInvitation(token);
  }

  @override
  Future<Invitation> previewInvitation(String token) {
    return remoteDataSource.previewInvitation(token);
  }
}
