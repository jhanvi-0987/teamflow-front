import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router.dart';
import '../../../../core/notifications/in_app_notification_service.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../domain/models/channel_model.dart';
import '../../domain/models/message_notification.dart';
import '../screens/channel_chat_screen.dart';
import 'chat_providers.dart';

/// Tracks which channel is actively open on the screen
final activeChatChannelProvider = StateProvider<String?>((ref) => null);

/// State holding unread message counts per channel
class UnreadMessagesState {
  final Map<String, int> channelUnreadCounts;

  const UnreadMessagesState({
    this.channelUnreadCounts = const {},
  });

  int get totalUnreadCount =>
      channelUnreadCounts.values.fold(0, (sum, count) => sum + count);

  int countForChannel(String channelId) => channelUnreadCounts[channelId] ?? 0;

  UnreadMessagesState copyWith({
    Map<String, int>? channelUnreadCounts,
  }) {
    return UnreadMessagesState(
      channelUnreadCounts: channelUnreadCounts ?? this.channelUnreadCounts,
    );
  }
}

class UnreadMessagesNotifier extends StateNotifier<UnreadMessagesState> {
  final Ref _ref;
  final SocketService _socketService;
  StreamSubscription? _subscription;

  UnreadMessagesNotifier({
    required Ref ref,
    required SocketService socketService,
  })  : _ref = ref,
        _socketService = socketService,
        super(const UnreadMessagesState()) {
    _initListener();
  }

  void _initListener() {
    _socketService.connect();
    _subscription = _socketService.onMessageNotification.listen((data) {
      _handleIncomingNotification(data);
    });
  }

  @visibleForTesting
  void handleNotificationForTest(Map<String, dynamic> data) {
    _handleIncomingNotification(data);
  }

  void _handleIncomingNotification(Map<String, dynamic> data) {
    try {
      debugPrint('[UnreadMessagesNotifier] Received notification event: $data');
      final notif = MessageNotification.fromJson(data);
      if (notif.channelId.isEmpty) return;

      final activeChannelId = _ref.read(activeChatChannelProvider);
      final isCurrentChannelOpen = (activeChannelId == notif.channelId);

      // Only increment unread badge counters if user does NOT currently have this channel open
      if (!isCurrentChannelOpen) {
        final updated = Map<String, int>.from(state.channelUnreadCounts);
        updated[notif.channelId] = (updated[notif.channelId] ?? 0) + 1;
        state = state.copyWith(channelUnreadCounts: updated);

        // Refresh workspace channels list to update preview and ordering
        if (notif.workspaceId.isNotEmpty) {
          _ref.invalidate(workspaceChannelsProvider(notif.workspaceId));
        }
      }

      debugPrint(
        '[UnreadMessagesNotifier] Displaying in-app notification banner: ${notif.senderName} (#${notif.channelName})',
      );

      // Always show in-app banner toast for all incoming messages as requested
      InAppNotificationService.show(
        notif,
        onTap: (notification) => openChannelFromNotification(notification),
      );

      // Post native notification to the phone status bar / notification drawer
      LocalNotificationService.showNotification(notif).catchError((_) {});
    } catch (e) {
      debugPrint('[UnreadMessagesNotifier] Error handling notification: $e');
    }
  }

  void markChannelAsRead(String channelId) {
    if (!state.channelUnreadCounts.containsKey(channelId)) return;
    final updated = Map<String, int>.from(state.channelUnreadCounts);
    updated.remove(channelId);
    state = state.copyWith(channelUnreadCounts: updated);
  }

  void clearAll() {
    state = const UnreadMessagesState(channelUnreadCounts: {});
  }

  void openChannelFromNotification(MessageNotification notification) {
    markChannelAsRead(notification.channelId);

    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    final channel = ChannelModel(
      id: notification.channelId,
      workspaceId: notification.workspaceId,
      name: notification.channelName,
      type: notification.isDM ? ChannelType.directMessage : ChannelType.public,
      updatedAt: notification.createdAt,
    );

    Navigator.of(navContext).push(
      MaterialPageRoute(
        builder: (_) => ChannelChatScreen(channel: channel),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final unreadMessagesProvider =
    StateNotifierProvider<UnreadMessagesNotifier, UnreadMessagesState>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return UnreadMessagesNotifier(
    ref: ref,
    socketService: socketService,
  );
});
