import '../models/app_notification.dart';

abstract class NotificationsRepository {
  Future<({List<AppNotification> items, int unreadCount, String? nextCursor})>
      getNotifications({int limit = 50, String? cursor, bool unreadOnly = false});

  Future<int> getUnreadCount();

  Future<({AppNotification notification, int unreadCount})> markAsRead(
      String notificationId);

  Future<({int markedCount, int unreadCount})> markAllAsRead();
}
