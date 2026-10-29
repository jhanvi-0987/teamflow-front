import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/chat/domain/models/message_model.dart';
import 'package:mobile/features/chat/domain/models/reaction_model.dart';

void main() {
  group('ReactionGroupModel', () {
    test('parses from JSON correctly', () {
      final json = {
        'emoji': '🔥',
        'count': 3,
        'userIds': ['u1', 'u2', 'u3'],
        'userNames': ['Alice', 'Bob', 'Charlie'],
      };

      final reaction = ReactionGroupModel.fromJson(json);

      expect(reaction.emoji, equals('🔥'));
      expect(reaction.count, equals(3));
      expect(reaction.userIds, equals(['u1', 'u2', 'u3']));
      expect(reaction.userNames, equals(['Alice', 'Bob', 'Charlie']));
      expect(reaction.hasReacted('u2'), isTrue);
      expect(reaction.hasReacted('u99'), isFalse);
    });

    test('serializes to JSON correctly', () {
      const reaction = ReactionGroupModel(
        emoji: '🚀',
        count: 2,
        userIds: ['u1', 'u2'],
        userNames: ['Alice', 'Bob'],
      );

      final json = reaction.toJson();

      expect(json['emoji'], equals('🚀'));
      expect(json['count'], equals(2));
      expect(json['userIds'], equals(['u1', 'u2']));
      expect(json['userNames'], equals(['Alice', 'Bob']));
    });
  });

  group('MessageModel with reactions', () {
    test('parses reactions list from JSON', () {
      final json = {
        'id': 'msg-1',
        'channelId': 'chan-1',
        'senderId': 'u1',
        'content': 'Great job team!',
        'createdAt': '2026-10-29T10:00:00.000Z',
        'reactions': [
          {
            'emoji': '👍',
            'count': 1,
            'userIds': ['u2'],
            'userNames': ['Bob'],
          },
          {
            'emoji': '🎉',
            'count': 2,
            'userIds': ['u1', 'u3'],
            'userNames': ['Alice', 'Charlie'],
          }
        ],
      };

      final message = MessageModel.fromJson(json);

      expect(message.hasReactions, isTrue);
      expect(message.reactions.length, equals(2));
      expect(message.reactions[0].emoji, equals('👍'));
      expect(message.reactions[0].count, equals(1));
      expect(message.reactions[1].emoji, equals('🎉'));
      expect(message.reactions[1].count, equals(2));
      expect(message.reactions[1].hasReacted('u1'), isTrue);
    });

    test('copyWith updates reactions cleanly', () {
      final message = MessageModel(
        id: 'msg-1',
        channelId: 'chan-1',
        senderId: 'u1',
        senderName: 'Alice',
        senderEmail: 'alice@test.com',
        content: 'Hello',
        createdAt: DateTime.now(),
      );

      expect(message.hasReactions, isFalse);

      final updated = message.copyWith(reactions: const [
        ReactionGroupModel(
          emoji: '❤️',
          count: 1,
          userIds: ['u2'],
          userNames: ['Bob'],
        ),
      ]);

      expect(updated.hasReactions, isTrue);
      expect(updated.reactions.first.emoji, equals('❤️'));
      expect(updated.reactions.first.count, equals(1));
    });
  });
}
