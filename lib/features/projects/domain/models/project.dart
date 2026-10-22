import 'package:equatable/equatable.dart';

class Project extends Equatable {
  final String id;
  final String workspaceId;
  final String key;
  final String name;
  final String? description;
  final String status;
  final int taskCount;
  final Map<String, int>? tasksByStatus;
  final String? userRole;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.workspaceId,
    required this.key,
    required this.name,
    this.description,
    this.status = 'ACTIVE',
    this.taskCount = 0,
    this.tasksByStatus,
    this.userRole,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'ACTIVE';

  factory Project.fromJson(Map<String, dynamic> json) {
    Map<String, int>? statusMap;
    if (json['tasksByStatus'] is Map) {
      statusMap = (json['tasksByStatus'] as Map).map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      );
    }

    return Project(
      id: json['id'] as String,
      workspaceId: json['workspaceId'] as String,
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      taskCount: (json['taskCount'] as num?)?.toInt() ??
          (json['_count']?['tasks'] as num?)?.toInt() ??
          0,
      tasksByStatus: statusMap,
      userRole: json['userRole'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspaceId': workspaceId,
      'key': key,
      'name': name,
      'description': description,
      'status': status,
      'taskCount': taskCount,
      'tasksByStatus': tasksByStatus,
      'userRole': userRole,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        workspaceId,
        key,
        name,
        description,
        status,
        taskCount,
        tasksByStatus,
        userRole,
        createdAt,
        updatedAt,
      ];
}
