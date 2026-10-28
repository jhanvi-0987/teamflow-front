import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/token_storage.dart';
import 'package:mobile/core/realtime/socket_service.dart';
import 'package:mobile/features/notifications/domain/models/app_notification.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:mobile/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:mobile/features/notifications/presentation/widgets/notification_bell_button.dart';

class MockNotificationsRepository implements NotificationsRepository {
  int count;
  MockNotificationsRepository({this.count = 0});

  @override
  Future<({List<AppNotification> items, int unreadCount, String? nextCursor})>
      getNotifications({int limit = 50, String? cursor, bool unreadOnly = false}) async {
    return (items: <AppNotification>[], unreadCount: count, nextCursor: null);
  }

  @override
  Future<int> getUnreadCount() async => count;

  @override
  Future<({AppNotification notification, int unreadCount})> markAsRead(
      String notificationId) async {
    return (
      notification: AppNotification(
        id: notificationId,
        userId: 'u',
        type: 'TASK_ASSIGNED',
        payload: const {},
        createdAt: DateTime.now(),
      ),
      unreadCount: 0
    );
  }

  @override
  Future<({int markedCount, int unreadCount})> markAllAsRead() async {
    return (markedCount: count, unreadCount: 0);
  }
}

void main() {
  testWidgets('NotificationBellButton displays bell icon and no badge when unread is 0',
      (WidgetTester tester) async {
    final repo = MockNotificationsRepository(count: 0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repo),
          socketServiceProvider.overrideWithValue(
            SocketService(tokenStorage: InMemoryTokenStorage()),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NotificationBellButton(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify bell icon is present
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    // Verify badge text is not shown
    expect(find.text('0'), findsNothing);
  });

  testWidgets('NotificationBellButton displays badge count when unread > 0',
      (WidgetTester tester) async {
    final repo = MockNotificationsRepository(count: 5);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repo),
          socketServiceProvider.overrideWithValue(
            SocketService(tokenStorage: InMemoryTokenStorage()),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NotificationBellButton(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify active bell icon is present
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    // Verify unread badge count '5' is displayed
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('NotificationBellButton shows 99+ for large counts',
      (WidgetTester tester) async {
    final repo = MockNotificationsRepository(count: 120);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repo),
          socketServiceProvider.overrideWithValue(
            SocketService(tokenStorage: InMemoryTokenStorage()),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NotificationBellButton(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('99+'), findsOneWidget);
  });
}
