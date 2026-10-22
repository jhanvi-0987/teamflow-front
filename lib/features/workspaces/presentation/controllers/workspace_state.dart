import 'package:equatable/equatable.dart';
import '../../domain/models/workspace.dart';

class WorkspaceState extends Equatable {
  final List<Workspace> workspaces;
  final Workspace? currentWorkspace;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const WorkspaceState({
    this.workspaces = const [],
    this.currentWorkspace,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  WorkspaceState copyWith({
    List<Workspace>? workspaces,
    Workspace? currentWorkspace,
    bool clearCurrentWorkspace = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return WorkspaceState(
      workspaces: workspaces ?? this.workspaces,
      currentWorkspace: clearCurrentWorkspace
          ? null
          : (currentWorkspace ?? this.currentWorkspace),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        workspaces,
        currentWorkspace,
        isLoading,
        errorMessage,
        successMessage,
      ];
}
