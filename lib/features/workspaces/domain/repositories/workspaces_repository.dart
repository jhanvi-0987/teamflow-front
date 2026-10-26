import '../models/workspace.dart';
import '../models/workspace_member.dart';
import '../models/invitation.dart';

abstract class WorkspacesRepository {
  Future<Workspace> createWorkspace({required String name, String? slug});
  Future<List<Workspace>> getUserWorkspaces();
  Future<Workspace> getWorkspaceById(String id);
  Future<Workspace> updateWorkspace(String id, {String? name, String? slug});
  Future<void> archiveWorkspace(String id);
  Future<void> transferOwnership(String workspaceId, String newOwnerId);
  Future<void> leaveWorkspace(String workspaceId);

  // Members
  Future<List<WorkspaceMember>> getMembers(String workspaceId, {String? query});
  Future<WorkspaceMember> updateMemberRole(
    String workspaceId,
    String userId,
    WorkspaceRole role,
  );
  Future<void> removeMember(String workspaceId, String userId);

  // Invitations
  Future<Invitation> inviteMember(
    String workspaceId,
    String email,
    WorkspaceRole role,
  );
  Future<List<Invitation>> getPendingInvitations(String workspaceId);
  Future<void> revokeInvitation(String workspaceId, String invitationId);
  Future<Workspace> acceptInvitation(String token);
  Future<void> declineInvitation(String token);
  Future<Invitation> previewInvitation(String token);
}
