import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/workspace.dart';
import '../../domain/repositories/workspaces_repository.dart';
import 'workspace_state.dart';

class WorkspaceController extends StateNotifier<WorkspaceState> {
  final WorkspacesRepository _repository;

  WorkspaceController(this._repository) : super(const WorkspaceState());

  Future<void> loadWorkspaces() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.getUserWorkspaces();
      Workspace? active = state.currentWorkspace;
      if (active == null && list.isNotEmpty) {
        active = list.first;
      } else if (active != null) {
        active = list.where((w) => w.id == active!.id).firstOrNull ??
            (list.isNotEmpty ? list.first : null);
      }
      state = state.copyWith(
        workspaces: list,
        currentWorkspace: active,
        clearCurrentWorkspace: active == null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void switchWorkspace(Workspace workspace) {
    state = state.copyWith(currentWorkspace: workspace);
  }

  Future<bool> createWorkspace({required String name, String? slug}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _repository.createWorkspace(name: name, slug: slug);
      final updatedList = [created, ...state.workspaces];
      state = state.copyWith(
        workspaces: updatedList,
        currentWorkspace: created,
        isLoading: false,
        successMessage: 'Workspace "${created.name}" created successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateWorkspace(String id, {String? name, String? slug}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.updateWorkspace(id, name: name, slug: slug);
      final updatedList = state.workspaces
          .map((w) => w.id == id ? updated : w)
          .toList();
      state = state.copyWith(
        workspaces: updatedList,
        currentWorkspace: state.currentWorkspace?.id == id ? updated : null,
        isLoading: false,
        successMessage: 'Workspace updated',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> archiveWorkspace(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.archiveWorkspace(id);
      await loadWorkspaces();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Workspace archived',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> transferOwnership(String workspaceId, String newOwnerId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.transferOwnership(workspaceId, newOwnerId);
      await loadWorkspaces();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Ownership transferred successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> leaveWorkspace(String workspaceId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.leaveWorkspace(workspaceId);
      await loadWorkspaces();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'You have left the workspace',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> acceptInvitation(String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final joined = await _repository.acceptInvitation(token);
      await loadWorkspaces();
      state = state.copyWith(
        currentWorkspace: joined,
        isLoading: false,
        successMessage: 'Successfully joined ${joined.name}',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}
