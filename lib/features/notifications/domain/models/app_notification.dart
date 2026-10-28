import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum NotificationCategory {
  all,
  unread,
  tasks,
  mentions,
  invites,
}

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.payload,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  String? get taskId => payload['taskId']?.toString();
  String? get taskTitle => payload['taskTitle']?.toString();
  String? get projectId => payload['projectId']?.toString();
  String? get projectName => payload['projectName']?.toString();
  String? get workspaceId => payload['workspaceId']?.toString();
  String? get workspaceName => payload['workspaceName']?.toString();
  String? get actorName => payload['actorName']?.toString();
  String? get inviteToken => payload['inviteToken']?.toString();
  String? get role => payload['role']?.toString();
  String? get channelId => payload['channelId']?.toString();
  String? get channelName => payload['channelName']?.toString();
  String? get oldStatus => payload['oldStatus']?.toString();
  String? get newStatus => payload['newStatus']?.toString();

  String get title {
    switch (type.toUpperCase()) {
      case 'TASK_ASSIGNED':
        return 'Task Assigned';
      case 'TASK_STATUS_CHANGED':
        return 'Task Status Changed';
      case 'MENTION':
        return 'Mentioned You';
      case 'WORKSPACE_INVITATION':
        return 'Workspace Invitation';
      case 'TASK_COMMENT':
        return 'New Comment';
      default:
        return 'Notification';
    }
  }

  String get message {
    if (payload['message'] != null && payload['message'].toString().isNotEmpty) {
      return payload['message'].toString();
    }
    if (payload['content'] != null && payload['content'].toString().isNotEmpty) {
      return payload['content'].toString();
    }
    if (type == 'TASK_ASSIGNED') {
      return '${actorName ?? 'A team member'} assigned you to "${taskTitle ?? 'a task'}"';
    }
    if (type == 'TASK_STATUS_CHANGED') {
      return 'Task "${taskTitle ?? 'a task'}" changed to ${newStatus ?? ''}';
    }
    if (type == 'WORKSPACE_INVITATION') {
      return 'You were invited to join "${workspaceName ?? 'a workspace'}"';
    }
    return 'You have a new activity update';
  }

  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  IconData get iconData {
    switch (type.toUpperCase()) {
      case 'TASK_ASSIGNED':
        return Icons.assignment_ind_rounded;
      case 'TASK_STATUS_CHANGED':
        return Icons.published_with_changes_rounded;
      case 'MENTION':
        return Icons.alternate_email_rounded;
      case 'WORKSPACE_INVITATION':
        return Icons.mark_email_unread_rounded;
      case 'TASK_COMMENT':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color get categoryColor {
    switch (type.toUpperCase()) {
      case 'TASK_ASSIGNED':
        return const Color(0xFFD97706); // Warm Amber
      case 'TASK_STATUS_CHANGED':
        return const Color(0xFF059669); // Emerald Green
      case 'MENTION':
        return const Color(0xFF7C3AED); // Royal Violet
      case 'WORKSPACE_INVITATION':
        return const Color(0xFF2563EB); // Vibrant Indigo
      case 'TASK_COMMENT':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  NotificationCategory get category {
    switch (type.toUpperCase()) {
      case 'TASK_ASSIGNED':
      case 'TASK_STATUS_CHANGED':
        return NotificationCategory.tasks;
      case 'MENTION':
      case 'TASK_COMMENT':
        return NotificationCategory.mentions;
      case 'WORKSPACE_INVITATION':
        return NotificationCategory.invites;
      default:
        return NotificationCategory.all;
    }
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    Map<String, dynamic>? payload,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    Map<String, dynamic> parsedPayload = {};
    if (json['payload'] != null) {
      if (json['payload'] is Map) {
        parsedPayload = Map<String, dynamic>.from(json['payload'] as Map);
      }
    }

    return AppNotification(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'GENERIC',
      payload: parsedPayload,
      readAt: json['readAt'] != null || json['read_at'] != null
          ? parseDate(json['readAt'] ?? json['read_at'])
          : null,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'payload': payload,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
