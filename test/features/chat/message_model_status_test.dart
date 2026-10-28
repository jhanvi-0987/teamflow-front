import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/chat/domain/models/message_model.dart';

void main() {
  group('MessageModel Status & Delivery Ticks', () {
    test('defaults to sent status when not specified', () {
      final msg = MessageModel(
        id: 'msg-1',
        channelId: 'chan-1',
        senderId: 'user-1',
        senderName: 'Alice',
        senderEmail: 'alice@teamflow.dev',
        content: 'Hello World',
        createdAt: DateTime(2026, 10, 28, 12, 0),
      );

      expect(msg.status, equals('sent'));
      expect(msg.deliveredAt, isNull);
      expect(msg.readAt, isNull);
    });

    test('parses status, deliveredAt, and readAt from json', () {
      final json = {
        'id': 'msg-2',
        'channelId': 'chan-1',
        'senderId': 'user-1',
        'sender': {'name': 'Alice', 'email': 'alice@teamflow.dev'},
        'content': 'Check this out',
        'status': 'read',
        'deliveredAt': '2026-10-28T12:01:00.000Z',
        'readAt': '2026-10-28T12:02:00.000Z',
        'createdAt': '2026-10-28T12:00:00.000Z',
      };

      final msg = MessageModel.fromJson(json);

      expect(msg.status, equals('read'));
      expect(msg.deliveredAt, equals(DateTime.parse('2026-10-28T12:01:00.000Z')));
      expect(msg.readAt, equals(DateTime.parse('2026-10-28T12:02:00.000Z')));
    });

    test('copyWith updates status correctly from sent -> delivered -> read', () {
      final sent = MessageModel(
        id: 'msg-1',
        channelId: 'chan-1',
        senderId: 'user-1',
        senderName: 'Alice',
        senderEmail: 'alice@teamflow.dev',
        content: 'Hello',
        status: 'sent',
        createdAt: DateTime(2026, 10, 28, 12, 0),
      );

      final delivered = sent.copyWith(
        status: 'delivered',
        deliveredAt: DateTime(2026, 10, 28, 12, 1),
      );
      expect(delivered.status, equals('delivered'));
      expect(delivered.deliveredAt, isNotNull);

      final read = delivered.copyWith(
        status: 'read',
        readAt: DateTime(2026, 10, 28, 12, 2),
      );
      expect(read.status, equals('read'));
      expect(read.readAt, isNotNull);
    });

    test('toJson preserves status and delivery timestamps', () {
      final msg = MessageModel(
        id: 'msg-1',
        channelId: 'chan-1',
        senderId: 'user-1',
        senderName: 'Alice',
        senderEmail: 'alice@teamflow.dev',
        content: 'Hello',
        status: 'delivered',
        deliveredAt: DateTime.parse('2026-10-28T12:01:00.000Z'),
        createdAt: DateTime.parse('2026-10-28T12:00:00.000Z'),
      );

      final map = msg.toJson();
      expect(map['status'], equals('delivered'));
      expect(map['deliveredAt'], equals('2026-10-28T12:01:00.000Z'));
      expect(map['readAt'], isNull);
    });
  });
}
