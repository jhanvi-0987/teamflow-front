import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/chat/domain/models/message_notification.dart';

void main() {
  group('MessageNotification Model', () {
    test('parses from valid json correctly', () {
      final json = {
        'channelId': 'chan-123',
        'channelName': 'general',
        'isDM': false,
        'senderId': 'user-1',
        'senderName': 'Alice',
        'senderEmail': 'alice@teamflow.com',
        'content': 'Hello team!',
        'taskId': 'task-99',
        'taskTitle': 'Fix auth bug',
        'workspaceId': 'ws-1',
        'createdAt': '2026-10-27T10:00:00.000Z',
      };

      final notif = MessageNotification.fromJson(json);

      expect(notif.channelId, 'chan-123');
      expect(notif.channelName, 'general');
      expect(notif.isDM, isFalse);
      expect(notif.senderId, 'user-1');
      expect(notif.senderName, 'Alice');
      expect(notif.senderEmail, 'alice@teamflow.com');
      expect(notif.content, 'Hello team!');
      expect(notif.taskId, 'task-99');
      expect(notif.taskTitle, 'Fix auth bug');
      expect(notif.workspaceId, 'ws-1');
      expect(notif.createdAt, DateTime.parse('2026-10-27T10:00:00.000Z'));
    });

    test('parses DM notifications and handles missing optional fields gracefully', () {
      final json = {
        'channelId': 'dm-456',
        'channelName': 'Bob',
        'isDM': true,
        'senderId': 'user-2',
        'senderEmail': 'bob@teamflow.com',
        'content': 'Hey, quick question',
        'workspaceId': 'ws-1',
      };

      final notif = MessageNotification.fromJson(json);

      expect(notif.channelId, 'dm-456');
      expect(notif.channelName, 'Bob');
      expect(notif.isDM, isTrue);
      expect(notif.senderName, 'bob@teamflow.com');
      expect(notif.taskId, isNull);
      expect(notif.taskTitle, isNull);
      expect(notif.createdAt, isNotNull);
    });

    test('equatable props work for value comparisons', () {
      final date = DateTime(2026, 10, 27, 10, 0);

      final notif1 = MessageNotification(
        channelId: 'chan-1',
        channelName: 'dev',
        isDM: false,
        senderId: 'u1',
        senderName: 'Carol',
        senderEmail: 'carol@flow.io',
        content: 'Check PR',
        workspaceId: 'ws-1',
        createdAt: date,
      );

      final notif2 = MessageNotification(
        channelId: 'chan-1',
        channelName: 'dev',
        isDM: false,
        senderId: 'u1',
        senderName: 'Carol',
        senderEmail: 'carol@flow.io',
        content: 'Check PR',
        workspaceId: 'ws-1',
        createdAt: date,
      );

      expect(notif1, equals(notif2));
    });
  });
}
