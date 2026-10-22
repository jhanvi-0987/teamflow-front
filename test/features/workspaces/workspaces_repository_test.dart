import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/features/workspaces/domain/models/workspace.dart';
import 'package:mobile/features/workspaces/domain/models/workspace_member.dart';
import 'package:mobile/features/workspaces/domain/models/invitation.dart';
import 'package:mobile/features/workspaces/domain/repositories/workspaces_repository.dart';
import 'package:mobile/features/workspaces/presentation/controllers/workspace_controller.dart';

class MockWorkspacesRepository implements WorkspacesRepository {
  final List<Workspace> _workspaces = [];
  final List<WorkspaceMember> _members = [];
  final List<Invitation> _invitations = [];
  bool shouldFail = false;

  @override
  Future<Workspace> createWorkspace({required String name, String? slug}) async {
    if (shouldFail) {
      throw const WorkspaceFailure(
        code: 'SLUG_ALREADY_EXISTS',
        message: 'Slug already taken',
      );
    }
    final ws = Workspace(
      id: 'ws-${_workspaces.length + 1}',
      name: name,
      slug: slug ?? name.toLowerCase().replaceAll(' ', '-'),
      ownerId: 'user-1',
      role: WorkspaceRole.owner,
      memberCount: 1,
      projectCount: 0,
      createdAt: DateTime.now(),
    );
    _workspaces.add(ws);
    return ws;
  }

  @override
  Future<List<Workspace>> getUserWorkspaces() async {
    return List.from(_workspaces);
  }

  @override
  Future<Workspace> getWorkspaceById(String id) async {
    final ws = _workspaces.where((w) => w.id == id).firstOrNull;
    if (ws == null) {
      throw const WorkspaceFailure(
        code: 'WORKSPACE_NOT_FOUND',
        message: 'Not found',
      );
    }
    return ws;
  }

  @override
  Future<Workspace> updateWorkspace(String id, {String? name, String? slug}) async {
    final idx = _workspaces.indexWhere((w) => w.id == id);
    if (idx == -1) {
      throw const WorkspaceFailure(
        code: 'WORKSPACE_NOT_FOUND',
        message: 'Not found',
      );
    }
    final updated = _workspaces[idx].copyWith(
      name: name,
      slug: slug,
    );
    _workspaces[idx] = updated;
    return updated;
  }

  @override
  Future<void> archiveWorkspace(String id) async {
    final idx = _workspaces.indexWhere((w) => w.id == id);
    if (idx != -1) {
      _workspaces[idx] = _workspaces[idx].copyWith(archivedAt: DateTime.now());
    }
  }

  @override
  Future<void> transferOwnership(String workspaceId, String newOwnerId) async {
    final idx = _workspaces.indexWhere((w) => w.id == workspaceId);
    if (idx != -1) {
      _workspaces[idx] = _workspaces[idx].copyWith(role: WorkspaceRole.admin);
    }
  }

  @override
  Future<void> leaveWorkspace(String workspaceId) async {
    _workspaces.removeWhere((w) => w.id == workspaceId);
  }

  @override
  Future<List<WorkspaceMember>> getMembers(String workspaceId) async {
    return List.from(_members);
  }

  @override
  Future<WorkspaceMember> updateMemberRole(
    String workspaceId,
    String userId,
    WorkspaceRole role,
  ) async {
    final idx = _members.indexWhere((m) => m.userId == userId);
    final member = WorkspaceMember(
      id: 'mem-$userId',
      userId: userId,
      role: role,
      joinedAt: DateTime.now(),
      name: 'User $userId',
      email: '$userId@example.com',
    );
    if (idx != -1) {
      _members[idx] = member;
    } else {
      _members.add(member);
    }
    return member;
  }

  @override
  Future<void> removeMember(String workspaceId, String userId) async {
    _members.removeWhere((m) => m.userId == userId);
  }

  @override
  Future<Invitation> inviteMember(
    String workspaceId,
    String email,
    WorkspaceRole role,
  ) async {
    final inv = Invitation(
      id: 'inv-${_invitations.length + 1}',
      workspaceId: workspaceId,
      email: email,
      role: role,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      inviteToken: 'sample-raw-token-12345678',
    );
    _invitations.add(inv);
    return inv;
  }

  @override
  Future<List<Invitation>> getPendingInvitations(String workspaceId) async {
    return List.from(_invitations);
  }

  @override
  Future<void> revokeInvitation(String workspaceId, String invitationId) async {
    _invitations.removeWhere((i) => i.id == invitationId);
  }

  @override
  Future<Workspace> acceptInvitation(String token) async {
    final ws = Workspace(
      id: 'ws-invited',
      name: 'Invited Team',
      slug: 'invited-team',
      ownerId: 'owner-other',
      role: WorkspaceRole.member,
      createdAt: DateTime.now(),
    );
    _workspaces.add(ws);
    return ws;
  }

  @override
  Future<void> declineInvitation(String token) async {}

  @override
  Future<Invitation> previewInvitation(String token) async {
    return Invitation(
      id: 'inv-preview',
      workspaceId: 'ws-preview',
      workspaceName: 'Preview Org',
      email: 'user@example.com',
      role: WorkspaceRole.member,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
  }
}

void main() {
  group('Workspaces & RBAC Flow (Unit)', () {
    late MockWorkspacesRepository repository;
    late WorkspaceController controller;

    setUp(() {
      repository = MockWorkspacesRepository();
      controller = WorkspaceController(repository);
    });

    test('createWorkspace should create and automatically select as active', () async {
      final success = await controller.createWorkspace(
        name: 'Alpha Engineering',
        slug: 'alpha-eng',
      );

      expect(success, true);
      expect(controller.state.workspaces.length, 1);
      expect(controller.state.currentWorkspace?.name, 'Alpha Engineering');
      expect(controller.state.currentWorkspace?.role, WorkspaceRole.owner);
    });

    test('switchWorkspace should update currentWorkspace', () async {
      await controller.createWorkspace(name: 'Team 1');
      await controller.createWorkspace(name: 'Team 2');

      expect(controller.state.workspaces.length, 2);
      expect(controller.state.currentWorkspace?.name, 'Team 2');

      controller.switchWorkspace(controller.state.workspaces[1]);
      expect(controller.state.currentWorkspace?.name, 'Team 1');
    });

    test('acceptInvitation should add and switch to joined workspace', () async {
      final success = await controller.acceptInvitation('token-abc');

      expect(success, true);
      expect(controller.state.currentWorkspace?.name, 'Invited Team');
      expect(controller.state.currentWorkspace?.role, WorkspaceRole.member);
    });

    test('leaveWorkspace should remove workspace and clear or switch active', () async {
      await controller.createWorkspace(name: 'Workspace A');
      final wsId = controller.state.currentWorkspace!.id;

      final success = await controller.leaveWorkspace(wsId);
      expect(success, true);
      expect(controller.state.workspaces.isEmpty, true);
      expect(controller.state.currentWorkspace, isNull);
    });

    test('inviteMember should generate time-limited invitation token', () async {
      final inv = await repository.inviteMember(
        'ws-1',
        'colleague@example.com',
        WorkspaceRole.manager,
      );

      expect(inv.email, 'colleague@example.com');
      expect(inv.role, WorkspaceRole.manager);
      expect(inv.inviteToken, isNotNull);
      expect(inv.expiresAt.isAfter(DateTime.now()), true);
    });
  });
}
