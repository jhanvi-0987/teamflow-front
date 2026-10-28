import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/notifications_remote_data_source.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsRemoteDataSourceImpl(dio: apiClient.dio);
});

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  final remoteDataSource = ref.watch(notificationsRemoteDataSourceProvider);
  return NotificationsRepositoryImpl(remoteDataSource: remoteDataSource);
});

class NotificationsState {
  final List<AppNotification> items;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final NotificationCategory activeCategory;

  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.activeCategory = NotificationCategory.all,
  });

  List<AppNotification> get filteredItems {
    switch (activeCategory) {
      case NotificationCategory.unread:
        return items.where((n) => !n.isRead).toList();
      case NotificationCategory.tasks:
        return items.where((n) => n.category == NotificationCategory.tasks).toList();
      case NotificationCategory.mentions:
        return items.where((n) => n.category == NotificationCategory.mentions).toList();
      case NotificationCategory.invites:
        return items.where((n) => n.category == NotificationCategory.invites).toList();
      case NotificationCategory.all:
        return items;
    }
  }

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? isLoading,
    String? error,
    NotificationCategory? activeCategory,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeCategory: activeCategory ?? this.activeCategory,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repository;
  final SocketService _socketService;
  StreamSubscription? _socketSubscription;

  NotificationsNotifier({
    required NotificationsRepository repository,
    required SocketService socketService,
  })  : _repository = repository,
        _socketService = socketService,
        super(const NotificationsState()) {
    _init();
  }

  void _init() {
    _initSocket();
    loadNotifications();
  }

  void _initSocket() {
    _socketService.connect();
    _socketSubscription = _socketService.onNotificationCreated.listen((data) {
      handleRealtimeNotification(data);
    });
  }

  @visibleForTesting
  void handleRealtimeNotification(Map<String, dynamic> data) {
    try {
      final notif = AppNotification.fromJson(data);
      if (notif.id.isEmpty) return;

      // Skip duplicate
      if (state.items.any((n) => n.id == notif.id)) return;

      try {
        HapticFeedback.lightImpact();
      } catch (_) {}

      state = state.copyWith(
        items: [notif, ...state.items],
        unreadCount: state.unreadCount + (notif.isRead ? 0 : 1),
      );
    } catch (e) {
      debugPrint('[NotificationsNotifier] Failed to process real-time notification: $e');
    }
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.getNotifications(limit: 50);
      state = state.copyWith(
        items: result.items,
        unreadCount: result.unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final result = await _repository.getNotifications(limit: 50);
      state = state.copyWith(
        items: result.items,
        unreadCount: result.unreadCount,
        error: null,
      );
    } catch (e) {
      debugPrint('[NotificationsNotifier] Refresh error: $e');
    }
  }

  void setCategory(NotificationCategory category) {
    state = state.copyWith(activeCategory: category);
  }

  Future<void> markAsRead(String notificationId) async {
    final index = state.items.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;

    final target = state.items[index];
    if (target.isRead) return;

    // Optimistic update
    final updatedList = List<AppNotification>.from(state.items);
    updatedList[index] = target.copyWith(readAt: DateTime.now());
    final newUnreadCount = (state.unreadCount > 0) ? state.unreadCount - 1 : 0;

    state = state.copyWith(
      items: updatedList,
      unreadCount: newUnreadCount,
    );

    try {
      final result = await _repository.markAsRead(notificationId);
      state = state.copyWith(unreadCount: result.unreadCount);
    } catch (e) {
      debugPrint('[NotificationsNotifier] Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0) return;

    // Optimistic update
    final updatedList = state.items.map((n) {
      return n.isRead ? n : n.copyWith(readAt: DateTime.now());
    }).toList();

    state = state.copyWith(
      items: updatedList,
      unreadCount: 0,
    );

    try {
      await _repository.markAllAsRead();
    } catch (e) {
      debugPrint('[NotificationsNotifier] Failed to mark all as read: $e');
    }
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return NotificationsNotifier(
    repository: repository,
    socketService: socketService,
  );
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsNotifierProvider.select((s) => s.unreadCount));
});
