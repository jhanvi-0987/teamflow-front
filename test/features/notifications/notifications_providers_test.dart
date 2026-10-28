import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/token_storage.dart';
import 'package:mobile/core/realtime/socket_service.dart';
import 'package:mobile/features/notifications/domain/models/app_notification.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:mobile/features/notifications/presentation/providers/notifications_providers.dart';

class MockNotificationsRepository implements NotificationsRepository {
  List<AppNotification> items = [];
  int unreadCount = 0;

  @override
  Future<({List<AppNotification> items, int unreadCount, String? nextCursor})>
      getNotifications({int limit = 50, String? cursor, bool unreadOnly = false}) async {
    return (items: items, unreadCount: unreadCount, nextCursor: null);
  }

  @override
  Future<int> getUnreadCount() async {
    return unreadCount;
  }

  @override
  Future<({AppNotification notification, int unreadCount})> markAsRead(
      String notificationId) async {
    final idx = items.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(readAt: DateTime.now());
      unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
      return (notification: items[idx], unreadCount: unreadCount);
    }
    throw Exception('Notification not found');
  }

  @override
  Future<({int markedCount, int unreadCount})> markAllAsRead() async {
    final count = unreadCount;
    items = items.map((n) => n.copyWith(readAt: DateTime.now())).toList();
    unreadCount = 0;
    return (markedCount: count, unreadCount: 0);
  }
}

void main() {
  group('NotificationsNotifier & Providers', () {
    late ProviderContainer container;
    late MockNotificationsRepository repository;
    late SocketService socketService;

    final sampleNotifications = [
      AppNotification(
        id: 'n-1',
        userId: 'u-1',
        type: 'TASK_ASSIGNED',
        payload: const {'taskId': 'task-1'},
        createdAt: DateTime(2026, 10, 27, 9, 0),
      ),
      AppNotification(
        id: 'n-2',
        userId: 'u-1',
        type: 'TASK_STATUS_CHANGED',
        payload: const {'taskId': 'task-2', 'newStatus': 'DONE'},
        readAt: DateTime(2026, 10, 27, 10, 0),
        createdAt: DateTime(2026, 10, 27, 9, 30),
      ),
      AppNotification(
        id: 'n-3',
        userId: 'u-1',
        type: 'MENTION',
        payload: const {'taskId': 'task-3'},
        createdAt: DateTime(2026, 10, 27, 10, 0),
      ),
      AppNotification(
        id: 'n-4',
        userId: 'u-1',
        type: 'WORKSPACE_INVITATION',
        payload: const {'workspaceId': 'ws-1'},
        createdAt: DateTime(2026, 10, 27, 10, 15),
      ),
    ];

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      repository = MockNotificationsRepository();
      repository.items = List.from(sampleNotifications);
      repository.unreadCount = 3;

      socketService = SocketService(
        tokenStorage: InMemoryTokenStorage(),
        socketUrl: 'http://localhost:3000',
      );

      container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          socketServiceProvider.overrideWithValue(socketService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      socketService.dispose();
    });

    test('loads notifications on initialize', () async {
      await container.read(notificationsNotifierProvider.notifier).loadNotifications();

      final state = container.read(notificationsNotifierProvider);
      expect(state.items.length, 4);
      expect(state.unreadCount, 3);
      expect(state.isLoading, isFalse);
      expect(container.read(unreadNotificationCountProvider), 3);
    });

    test('filters notifications by category correctly', () async {
      await container.read(notificationsNotifierProvider.notifier).loadNotifications();
      final notifier = container.read(notificationsNotifierProvider.notifier);

      // All
      notifier.setCategory(NotificationCategory.all);
      expect(container.read(notificationsNotifierProvider).filteredItems.length, 4);

      // Unread
      notifier.setCategory(NotificationCategory.unread);
      expect(container.read(notificationsNotifierProvider).filteredItems.length, 3);

      // Tasks
      notifier.setCategory(NotificationCategory.tasks);
      expect(container.read(notificationsNotifierProvider).filteredItems.length, 2);

      // Mentions
      notifier.setCategory(NotificationCategory.mentions);
      expect(container.read(notificationsNotifierProvider).filteredItems.length, 1);

      // Invites
      notifier.setCategory(NotificationCategory.invites);
      expect(container.read(notificationsNotifierProvider).filteredItems.length, 1);
    });

    test('marks individual notification as read optimistically', () async {
      await container.read(notificationsNotifierProvider.notifier).loadNotifications();
      final notifier = container.read(notificationsNotifierProvider.notifier);

      expect(container.read(unreadNotificationCountProvider), 3);

      await notifier.markAsRead('n-1');

      final state = container.read(notificationsNotifierProvider);
      expect(state.unreadCount, 2);
      final notif1 = state.items.firstWhere((n) => n.id == 'n-1');
      expect(notif1.isRead, isTrue);
    });

    test('marks all notifications as read', () async {
      await container.read(notificationsNotifierProvider.notifier).loadNotifications();
      final notifier = container.read(notificationsNotifierProvider.notifier);

      expect(container.read(unreadNotificationCountProvider), 3);

      await notifier.markAllAsRead();

      final state = container.read(notificationsNotifierProvider);
      expect(state.unreadCount, 0);
      expect(state.items.every((n) => n.isRead), isTrue);
      expect(container.read(unreadNotificationCountProvider), 0);
    });

    test('handles real-time notification socket event', () async {
      await container.read(notificationsNotifierProvider.notifier).loadNotifications();
      final notifier = container.read(notificationsNotifierProvider.notifier);

      notifier.handleRealtimeNotification({
        'id': 'n-99',
        'userId': 'u-1',
        'type': 'TASK_ASSIGNED',
        'payload': {
          'taskId': 'task-99',
          'taskTitle': 'Urgent Fix',
        },
        'readAt': null,
        'createdAt': '2026-10-27T11:00:00.000Z',
      });

      final state = container.read(notificationsNotifierProvider);
      expect(state.items.length, 5);
      expect(state.items.first.id, 'n-99');
      expect(state.unreadCount, 4);
    });
  });
}
