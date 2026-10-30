import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/chat/domain/models/channel_model.dart';

void main() {
  group('ChannelModel.getDisplayName (Vice-Versa DM Names)', () {
    test('regular channel returns its name', () {
      final channel = ChannelModel(
        id: 'c-1',
        workspaceId: 'w-1',
        name: 'general',
        type: ChannelType.public,
        updatedAt: DateTime.now(),
      );

      expect(channel.getDisplayName('u-1'), equals('general'));
      expect(channel.getDisplayName('u-2'), equals('general'));
      expect(channel.getDisplayName(null), equals('general'));
    });

    test('direct message returns vice-versa name for each participant', () {
      final dmChannel = ChannelModel(
        id: 'dm-1',
        workspaceId: 'w-1',
        name: 'Direct Message',
        type: ChannelType.directMessage,
        members: const [
          ChannelMemberSummary(
            id: 'admin-id',
            name: 'Admin User',
            email: 'admin@teamflow.dev',
          ),
          ChannelMemberSummary(
            id: 'member-id',
            name: 'Test Member',
            email: 'member@teamflow.dev',
          ),
        ],
        updatedAt: DateTime.now(),
      );

      // When Admin is viewing the DM, they see Test Member
      expect(dmChannel.getDisplayName('admin-id'), equals('Test Member'));

      // When Test Member is viewing the DM, they see Admin User
      expect(dmChannel.getDisplayName('member-id'), equals('Admin User'));

      // When null or unknown user id, falls back gracefully to channel.name
      expect(dmChannel.getDisplayName(null), equals('Direct Message'));
    });

    test('fromJson parses members array and supports vice versa display name', () {
      final json = {
        'id': 'dm-4e0a',
        'workspaceId': 'ws-123',
        'name': 'Fallback Name',
        'type': 'DIRECT_MESSAGE',
        'membersCount': 2,
        'members': [
          {
            'id': 'user-admin',
            'name': 'Admin User',
            'email': 'admin@teamflow.dev',
          },
          {
            'id': 'user-test',
            'name': 'Test Member',
            'email': 'member@teamflow.dev',
          },
        ],
        'updatedAt': '2026-10-30T10:00:00.000Z',
      };

      final channel = ChannelModel.fromJson(json);

      expect(channel.isDM, isTrue);
      expect(channel.members.length, equals(2));
      expect(channel.getDisplayName('user-admin'), equals('Test Member'));
      expect(channel.getDisplayName('user-test'), equals('Admin User'));
    });
  });
}

