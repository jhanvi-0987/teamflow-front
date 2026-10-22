import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum TaskStatus {
  todo('TODO', 'To Do', Icons.radio_button_unchecked),
  inProgress('IN_PROGRESS', 'In Progress', Icons.timelapse),
  inReview('IN_REVIEW', 'In Review', Icons.rate_review_outlined),
  done('DONE', 'Done', Icons.check_circle);

  final String value;
  final String displayName;
  final IconData icon;

  const TaskStatus(this.value, this.displayName, this.icon);

  static TaskStatus fromString(String val) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TaskStatus.todo,
    );
  }

  Color get color {
    switch (this) {
      case TaskStatus.todo:
        return AppColors.textSecondary;
      case TaskStatus.inProgress:
        return const Color(0xFF2563EB); // Royal Blue
      case TaskStatus.inReview:
        return AppColors.warning;
      case TaskStatus.done:
        return AppColors.success;
    }
  }
}

enum TaskPriority {
  low('LOW', 'Low', Icons.arrow_downward, Color(0xFF6B7280)),
  medium('MEDIUM', 'Medium', Icons.remove, Color(0xFFD97706)),
  high('HIGH', 'High', Icons.arrow_upward, Color(0xFFEA580C)),
  urgent('URGENT', 'Urgent', Icons.priority_high, AppColors.error);

  final String value;
  final String displayName;
  final IconData icon;
  final Color color;

  const TaskPriority(this.value, this.displayName, this.icon, this.color);

  static TaskPriority fromString(String val) {
    return TaskPriority.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TaskPriority.medium,
    );
  }
}

class UserSummary extends Equatable {
  final String id;
  final String name;
  final String email;

  const UserSummary({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
      };

  @override
  List<Object?> get props => [id, name, email];
}

class TaskModel extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueAt;
  final double position;
  final int version;
  final UserSummary? assignee;
  final UserSummary? reporter;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.dueAt,
    this.position = 0,
    this.version = 1,
    this.assignee,
    this.reporter,
    this.commentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatus.fromString(json['status'] as String? ?? 'TODO'),
      priority: TaskPriority.fromString(json['priority'] as String? ?? 'MEDIUM'),
      dueAt: json['dueAt'] != null ? DateTime.parse(json['dueAt'] as String) : null,
      position: (json['position'] as num?)?.toDouble() ?? 0.0,
      version: (json['version'] as num?)?.toInt() ?? 1,
      assignee: json['assignee'] != null
          ? UserSummary.fromJson(json['assignee'] as Map<String, dynamic>)
          : null,
      reporter: json['reporter'] != null
          ? UserSummary.fromJson(json['reporter'] as Map<String, dynamic>)
          : null,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  TaskModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueAt,
    double? position,
    int? version,
    UserSummary? assignee,
    UserSummary? reporter,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueAt: dueAt ?? this.dueAt,
      position: position ?? this.position,
      version: version ?? this.version,
      assignee: assignee ?? this.assignee,
      reporter: reporter ?? this.reporter,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        title,
        description,
        status,
        priority,
        dueAt,
        position,
        version,
        assignee,
        reporter,
        commentCount,
        createdAt,
        updatedAt,
      ];
}
