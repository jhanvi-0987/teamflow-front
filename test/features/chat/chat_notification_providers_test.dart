import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/token_storage.dart';
import 'package:mobile/core/realtime/socket_service.dart';
import 'package:mobile/features/chat/presentation/providers/chat_notification_providers.dart';

void main() {
  group('Chat Notification & Unread Messages', () {
    late ProviderContainer container;
    late SocketService socketService;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      socketService = SocketService(
        tokenStorage: InMemoryTokenStorage(),
        socketUrl: 'http://localhost:3000',
      );
      container = ProviderContainer(
        overrides: [
          socketServiceProvider.overrideWithValue(socketService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      socketService.dispose();
    });

    test('initial state has zero total unread count', () {
      final state = container.read(unreadMessagesProvider);
      expect(state.totalUnreadCount, 0);
      expect(state.channelUnreadCounts, isEmpty);
    });

    test('increments channel unread count when notification is received', () async {
      final notifier = container.read(unreadMessagesProvider.notifier);

      notifier.handleNotificationForTest({
        'channelId': 'chan-1',
        'channelName': 'general',
        'isDM': false,
        'senderId': 'user-2',
        'senderName': 'Bob',
        'senderEmail': 'bob@test.com',
        'content': 'Hey team!',
        'workspaceId': 'ws-1',
      });

      var state = container.read(unreadMessagesProvider);
      expect(state.totalUnreadCount, 1);
      expect(state.countForChannel('chan-1'), 1);

      notifier.handleNotificationForTest({
        'channelId': 'chan-1',
        'channelName': 'general',
        'isDM': false,
        'senderId': 'user-2',
        'senderName': 'Bob',
        'senderEmail': 'bob@test.com',
        'content': 'Another message',
        'workspaceId': 'ws-1',
      });

      state = container.read(unreadMessagesProvider);
      expect(state.totalUnreadCount, 2);
      expect(state.countForChannel('chan-1'), 2);

      notifier.handleNotificationForTest({
        'channelId': 'chan-2',
        'channelName': 'random',
        'isDM': false,
        'senderId': 'user-3',
        'senderName': 'Charlie',
        'senderEmail': 'charlie@test.com',
        'content': 'Lunch anyone?',
        'workspaceId': 'ws-1',
      });

      state = container.read(unreadMessagesProvider);
      expect(state.totalUnreadCount, 3);
      expect(state.countForChannel('chan-1'), 2);
      expect(state.countForChannel('chan-2'), 1);
    });

    test('markChannelAsRead decrements channel and total unread counts', () {
      final notifier = container.read(unreadMessagesProvider.notifier);

      notifier.handleNotificationForTest({
        'channelId': 'chan-1',
        'channelName': 'general',
        'isDM': false,
        'senderId': 'user-2',
        'senderName': 'Bob',
        'senderEmail': 'bob@test.com',
        'content': 'Message 1',
        'workspaceId': 'ws-1',
      });
      notifier.handleNotificationForTest({
        'channelId': 'chan-2',
        'channelName': 'announcements',
        'isDM': false,
        'senderId': 'user-3',
        'senderName': 'Admin',
        'senderEmail': 'admin@test.com',
        'content': 'Message 2',
        'workspaceId': 'ws-1',
      });

      expect(container.read(unreadMessagesProvider).totalUnreadCount, 2);

      notifier.markChannelAsRead('chan-1');

      final state = container.read(unreadMessagesProvider);
      expect(state.totalUnreadCount, 1);
      expect(state.countForChannel('chan-1'), 0);
      expect(state.countForChannel('chan-2'), 1);
    });

    test('does not increment unread count if channel is currently active', () {
      final notifier = container.read(unreadMessagesProvider.notifier);

      // Set active channel to 'chan-active'
      container.read(activeChatChannelProvider.notifier).state = 'chan-active';

      notifier.handleNotificationForTest({
        'channelId': 'chan-active',
        'channelName': 'dev',
        'isDM': false,
        'senderId': 'user-4',
        'senderName': 'Dev Lead',
        'senderEmail': 'lead@test.com',
        'content': 'Deploying soon',
        'workspaceId': 'ws-1',
      });

      final state = container.read(unreadMessagesProvider);
      expect(state.totalUnreadCount, 0);
      expect(state.countForChannel('chan-active'), 0);
    });

    test('updates channel last message preview and sender immediately when notification is received', () {
      final notifier = container.read(unreadMessagesProvider.notifier);

      notifier.handleNotificationForTest({
        'channelId': 'chan-preview',
        'channelName': 'general',
        'isDM': false,
        'senderId': 'user-5',
        'senderName': 'Alice',
        'senderEmail': 'alice@test.com',
        'content': 'Check out the new design',
        'workspaceId': 'ws-1',
      });

      final state = container.read(unreadMessagesProvider);
      expect(state.lastMessageForChannel('chan-preview'), 'Check out the new design');
      expect(state.lastSenderForChannel('chan-preview'), 'Alice');
      expect(state.lastTimeForChannel('chan-preview'), isNotNull);
    });
  });
}
