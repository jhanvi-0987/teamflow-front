import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/chat/domain/models/message_model.dart';

void main() {
  group('MessageModel Actions (Reply, Pin, Forward)', () {
    test('parses replyTo correctly from JSON', () {
      final json = {
        'id': 'msg-2',
        'channelId': 'chan-1',
        'senderId': 'user-1',
        'content': 'I agree with this completely',
        'createdAt': '2026-10-29T10:05:00.000Z',
        'replyToId': 'msg-1',
        'replyTo': {
          'id': 'msg-1',
          'content': 'Should we launch Phase 9 tomorrow?',
          'sender': {
            'id': 'user-2',
            'name': 'Bob Smith',
          },
        },
      };

      final msg = MessageModel.fromJson(json);

      expect(msg.isReply, isTrue);
      expect(msg.replyToId, equals('msg-1'));
      expect(msg.replyTo, isNotNull);
      expect(msg.replyTo!.id, equals('msg-1'));
      expect(msg.replyTo!.content, equals('Should we launch Phase 9 tomorrow?'));
      expect(msg.replyTo!.senderName, equals('Bob Smith'));
    });

    test('parses isPinned and pinnedBy correctly from JSON', () {
      final json = {
        'id': 'msg-3',
        'channelId': 'chan-1',
        'senderId': 'user-1',
        'content': 'Sprint goal: finalize chat interactions',
        'createdAt': '2026-10-29T10:00:00.000Z',
        'isPinned': true,
        'pinnedAt': '2026-10-29T10:10:00.000Z',
        'pinnedBy': {
          'id': 'user-lead',
          'name': 'Tech Lead',
        },
      };

      final msg = MessageModel.fromJson(json);

      expect(msg.isPinned, isTrue);
      expect(msg.pinnedAt, isNotNull);
      expect(msg.pinnedById, equals('user-lead'));
      expect(msg.pinnedByName, equals('Tech Lead'));
    });

    test('detects forwarded messages via isForwarded getter', () {
      final regularMsg = MessageModel(
        id: 'msg-reg',
        channelId: 'chan-1',
        senderId: 'u1',
        senderName: 'Alice',
        senderEmail: 'alice@test.com',
        content: 'Standard direct message',
        createdAt: DateTime.now(),
      );

      final forwardedMsg = MessageModel(
        id: 'msg-fwd',
        channelId: 'chan-1',
        senderId: 'u1',
        senderName: 'Alice',
        senderEmail: 'alice@test.com',
        content: '[Forwarded from Bob]:\nImportant notice',
        createdAt: DateTime.now(),
      );

      expect(regularMsg.isForwarded, isFalse);
      expect(forwardedMsg.isForwarded, isTrue);
    });

    test('copyWith updates isPinned and replyTo cleanly', () {
      final msg = MessageModel(
        id: 'msg-4',
        channelId: 'chan-1',
        senderId: 'u1',
        senderName: 'Alice',
        senderEmail: 'alice@test.com',
        content: 'Original note',
        createdAt: DateTime.now(),
      );

      expect(msg.isPinned, isFalse);

      final pinned = msg.copyWith(
        isPinned: true,
        pinnedAt: DateTime.now(),
        pinnedByName: 'Lead',
      );

      expect(pinned.isPinned, isTrue);
      expect(pinned.pinnedByName, equals('Lead'));
    });
  });
}

