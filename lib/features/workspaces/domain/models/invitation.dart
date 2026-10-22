import 'package:equatable/equatable.dart';
import 'workspace.dart';

class Invitation extends Equatable {
  final String id;
  final String workspaceId;
  final String email;
  final WorkspaceRole role;
  final DateTime expiresAt;
  final String? inviteToken;
  final String? workspaceName;
  final bool isExpired;
  final bool isAccepted;

  const Invitation({
    required this.id,
    required this.workspaceId,
    required this.email,
    required this.role,
    required this.expiresAt,
    this.inviteToken,
    this.workspaceName,
    this.isExpired = false,
    this.isAccepted = false,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    final workspaceObj = json['workspace'] as Map<String, dynamic>?;
    return Invitation(
      id: json['id'] as String,
      workspaceId: json['workspaceId'] as String? ??
          json['workspace_id'] as String? ??
          (workspaceObj?['id'] as String? ?? ''),
      email: json['email'] as String,
      role: WorkspaceRole.fromString(json['role'] as String? ?? 'MEMBER'),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now(),
      inviteToken: json['inviteToken'] as String?,
      workspaceName: workspaceObj?['name'] as String?,
      isExpired: json['isExpired'] as bool? ?? false,
      isAccepted: json['isAccepted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        workspaceId,
        email,
        role,
        expiresAt,
        inviteToken,
        workspaceName,
        isExpired,
        isAccepted,
      ];
}
