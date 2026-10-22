import 'package:equatable/equatable.dart';

enum WorkspaceRole {
  owner,
  admin,
  manager,
  member;

  static WorkspaceRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'OWNER':
        return WorkspaceRole.owner;
      case 'ADMIN':
        return WorkspaceRole.admin;
      case 'MANAGER':
        return WorkspaceRole.manager;
      case 'MEMBER':
      default:
        return WorkspaceRole.member;
    }
  }

  String toApiString() => name.toUpperCase();

  String get displayName {
    switch (this) {
      case WorkspaceRole.owner:
        return 'Owner';
      case WorkspaceRole.admin:
        return 'Admin';
      case WorkspaceRole.manager:
        return 'Manager';
      case WorkspaceRole.member:
        return 'Member';
    }
  }

  bool get isOwner => this == WorkspaceRole.owner;
  bool get isAdminOrAbove => this == WorkspaceRole.owner || this == WorkspaceRole.admin;
  bool get isManagerOrAbove => isAdminOrAbove || this == WorkspaceRole.manager;
}

class Workspace extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String ownerId;
  final WorkspaceRole role;
  final int memberCount;
  final int projectCount;
  final DateTime? archivedAt;
  final DateTime createdAt;

  const Workspace({
    required this.id,
    required this.name,
    required this.slug,
    required this.ownerId,
    required this.role,
    this.memberCount = 1,
    this.projectCount = 0,
    this.archivedAt,
    required this.createdAt,
  });

  bool get isArchived => archivedAt != null;

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      ownerId: json['ownerId'] as String? ?? json['owner_id'] as String? ?? '',
      role: WorkspaceRole.fromString(json['role'] as String? ?? 'MEMBER'),
      memberCount: json['memberCount'] as int? ?? 1,
      projectCount: json['projectCount'] as int? ?? 0,
      archivedAt: json['archivedAt'] != null
          ? DateTime.tryParse(json['archivedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'ownerId': ownerId,
      'role': role.toApiString(),
      'memberCount': memberCount,
      'projectCount': projectCount,
      'archivedAt': archivedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Workspace copyWith({
    String? name,
    String? slug,
    WorkspaceRole? role,
    int? memberCount,
    int? projectCount,
    DateTime? archivedAt,
  }) {
    return Workspace(
      id: id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      ownerId: ownerId,
      role: role ?? this.role,
      memberCount: memberCount ?? this.memberCount,
      projectCount: projectCount ?? this.projectCount,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        ownerId,
        role,
        memberCount,
        projectCount,
        archivedAt,
        createdAt,
      ];
}
