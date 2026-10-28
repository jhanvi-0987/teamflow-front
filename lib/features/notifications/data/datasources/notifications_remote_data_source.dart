import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/app_notification.dart';

abstract class NotificationsRemoteDataSource {
  Future<({List<AppNotification> items, int unreadCount, String? nextCursor})>
      getNotifications({int limit = 50, String? cursor, bool unreadOnly = false});

  Future<int> getUnreadCount();

  Future<({AppNotification notification, int unreadCount})> markAsRead(
      String notificationId);

  Future<({int markedCount, int unreadCount})> markAllAsRead();
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final Dio dio;

  NotificationsRemoteDataSourceImpl({required this.dio});

  @override
  Future<({List<AppNotification> items, int unreadCount, String? nextCursor})>
      getNotifications({
    int limit = 50,
    String? cursor,
    bool unreadOnly = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'cursor': ?cursor,
        if (unreadOnly) 'unreadOnly': 'true',
      };

      final response = await dio.get(
        ApiEndpoints.notifications,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final rawList = data['items'] as List<dynamic>? ?? [];
      final items = rawList
          .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .toList();
      final unreadCount = data['unreadCount'] as int? ?? 0;
      final nextCursor = data['nextCursor'] as String?;

      return (items: items, unreadCount: unreadCount, nextCursor: nextCursor);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await dio.get(ApiEndpoints.notificationsUnreadCount);
      final data = response.data as Map<String, dynamic>;
      return data['count'] as int? ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<({AppNotification notification, int unreadCount})> markAsRead(
      String notificationId) async {
    try {
      final response =
          await dio.patch(ApiEndpoints.notificationRead(notificationId));
      final data = response.data as Map<String, dynamic>;
      final notif = AppNotification.fromJson(
          data['notification'] as Map<String, dynamic>);
      final unreadCount = data['unreadCount'] as int? ?? 0;

      return (notification: notif, unreadCount: unreadCount);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<({int markedCount, int unreadCount})> markAllAsRead() async {
    try {
      final response = await dio.post(ApiEndpoints.notificationsReadAll);
      final data = response.data as Map<String, dynamic>;
      final markedCount = data['markedCount'] as int? ?? 0;
      final unreadCount = data['unreadCount'] as int? ?? 0;

      return (markedCount: markedCount, unreadCount: unreadCount);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Failure _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? 'Notification server error';
        final code = data['code'] ?? 'NOTIFICATION_ERROR';
        return ServerFailure(
          message: message is List ? message.join(', ') : message.toString(),
          code: code.toString(),
        );
      }
      return ServerFailure(message: 'Request failed with status ${e.response!.statusCode}');
    }
    return const NetworkFailure();
  }
}
