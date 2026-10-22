import 'package:equatable/equatable.dart';
import 'workspace.dart';

class WorkspaceMember extends Equatable {
  final String id;
  final String userId;
  final WorkspaceRole role;
  final DateTime joinedAt;
  final String name;
  final String email;

  const WorkspaceMember({
    required this.id,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.name,
    required this.email,
  });

  factory WorkspaceMember.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] as Map<String, dynamic>? ?? {};
    return WorkspaceMember(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      role: WorkspaceRole.fromString(json['role'] as String? ?? 'MEMBER'),
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : DateTime.now(),
      name: userObj['name'] as String? ?? 'Unknown Member',
      email: userObj['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'role': role.toApiString(),
      'joinedAt': joinedAt.toIso8601String(),
      'user': {
        'name': name,
        'email': email,
      },
    };
  }

  @override
  List<Object?> get props => [id, userId, role, joinedAt, name, email];
}
