import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/domain/models/app_notification.dart';

void main() {
  group('AppNotification Model', () {
    test('parses task assignment notification correctly', () {
      final json = {
        'id': 'notif-1',
        'userId': 'user-1',
        'type': 'TASK_ASSIGNED',
        'payload': {
          'taskId': 'task-101',
          'taskTitle': 'Build Notifications Drawer',
          'projectId': 'proj-1',
          'projectName': 'TeamFlow',
          'workspaceId': 'ws-1',
          'actorName': 'Alice',
          'message': 'Alice assigned you to "Build Notifications Drawer"',
        },
        'readAt': null,
        'createdAt': '2026-10-27T10:00:00.000Z',
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 'notif-1');
      expect(notif.userId, 'user-1');
      expect(notif.type, 'TASK_ASSIGNED');
      expect(notif.isRead, isFalse);
      expect(notif.taskId, 'task-101');
      expect(notif.taskTitle, 'Build Notifications Drawer');
      expect(notif.projectId, 'proj-1');
      expect(notif.projectName, 'TeamFlow');
      expect(notif.workspaceId, 'ws-1');
      expect(notif.actorName, 'Alice');
      expect(notif.title, 'Task Assigned');
      expect(notif.message, 'Alice assigned you to "Build Notifications Drawer"');
      expect(notif.category, NotificationCategory.tasks);
      expect(notif.iconData, Icons.assignment_ind_rounded);
    });

    test('parses status change notification correctly', () {
      final json = {
        'id': 'notif-2',
        'userId': 'user-1',
        'type': 'TASK_STATUS_CHANGED',
        'payload': {
          'taskId': 'task-102',
          'taskTitle': 'Fix Auth Issue',
          'oldStatus': 'TODO',
          'newStatus': 'IN_PROGRESS',
          'message': 'Task "Fix Auth Issue" status changed to IN_PROGRESS',
        },
        'readAt': '2026-10-27T11:00:00.000Z',
        'createdAt': '2026-10-27T10:30:00.000Z',
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.isRead, isTrue);
      expect(notif.title, 'Task Status Changed');
      expect(notif.category, NotificationCategory.tasks);
      expect(notif.oldStatus, 'TODO');
      expect(notif.newStatus, 'IN_PROGRESS');
      expect(notif.iconData, Icons.published_with_changes_rounded);
    });

    test('parses mention notification correctly', () {
      final json = {
        'id': 'notif-3',
        'userId': 'user-1',
        'type': 'MENTION',
        'payload': {
          'taskId': 'task-103',
          'taskTitle': 'Database Migration',
          'actorName': 'Charlie',
          'content': '@user-1 please review',
        },
        'createdAt': '2026-10-27T10:30:00.000Z',
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.isRead, isFalse);
      expect(notif.title, 'Mentioned You');
      expect(notif.category, NotificationCategory.mentions);
      expect(notif.iconData, Icons.alternate_email_rounded);
    });

    test('parses workspace invitation notification correctly', () {
      final json = {
        'id': 'notif-4',
        'userId': 'user-1',
        'type': 'WORKSPACE_INVITATION',
        'payload': {
          'invitationId': 'inv-1',
          'workspaceId': 'ws-2',
          'workspaceName': 'Frontend Guild',
          'inviteToken': 'secret-token-123',
          'role': 'MEMBER',
        },
        'createdAt': '2026-10-27T10:30:00.000Z',
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.isRead, isFalse);
      expect(notif.title, 'Workspace Invitation');
      expect(notif.category, NotificationCategory.invites);
      expect(notif.workspaceName, 'Frontend Guild');
      expect(notif.inviteToken, 'secret-token-123');
      expect(notif.iconData, Icons.mark_email_unread_rounded);
    });

    test('handles relativeTime correctly', () {
      final justNow = AppNotification(
        id: '1',
        userId: 'u',
        type: 'TASK_ASSIGNED',
        payload: const {},
        createdAt: DateTime.now().subtract(const Duration(seconds: 15)),
      );
      expect(justNow.relativeTime, 'Just now');

      final minutesAgo = AppNotification(
        id: '2',
        userId: 'u',
        type: 'TASK_ASSIGNED',
        payload: const {},
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );
      expect(minutesAgo.relativeTime, '15m ago');

      final hoursAgo = AppNotification(
        id: '3',
        userId: 'u',
        type: 'TASK_ASSIGNED',
        payload: const {},
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(hoursAgo.relativeTime, '3h ago');
    });

    test('copyWith works as expected', () {
      final notif = AppNotification(
        id: '1',
        userId: 'u1',
        type: 'TASK_ASSIGNED',
        payload: const {'taskId': 't1'},
        createdAt: DateTime(2026, 10, 27),
      );

      final readTime = DateTime(2026, 10, 27, 12);
      final updated = notif.copyWith(readAt: readTime);

      expect(updated.isRead, isTrue);
      expect(updated.readAt, readTime);
      expect(updated.id, '1');
      expect(updated.taskId, 't1');
    });
  });
}
