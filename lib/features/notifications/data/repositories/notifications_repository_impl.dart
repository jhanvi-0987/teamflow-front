import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;

  NotificationsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<({List<AppNotification> items, int unreadCount, String? nextCursor})>
      getNotifications({
    int limit = 50,
    String? cursor,
    bool unreadOnly = false,
  }) {
    return remoteDataSource.getNotifications(
      limit: limit,
      cursor: cursor,
      unreadOnly: unreadOnly,
    );
  }

  @override
  Future<int> getUnreadCount() {
    return remoteDataSource.getUnreadCount();
  }

  @override
  Future<({AppNotification notification, int unreadCount})> markAsRead(
      String notificationId) {
    return remoteDataSource.markAsRead(notificationId);
  }

  @override
  Future<({int markedCount, int unreadCount})> markAllAsRead() {
    return remoteDataSource.markAllAsRead();
  }
}
