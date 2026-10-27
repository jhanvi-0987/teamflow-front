import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router.dart';
import '../../../../core/notifications/in_app_notification_service.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../domain/models/channel_model.dart';
import '../../domain/models/message_notification.dart';
import '../screens/channel_chat_screen.dart';
import 'chat_providers.dart';

/// Tracks which channel is actively open on the screen
final activeChatChannelProvider = StateProvider<String?>((ref) => null);

/// State holding unread message counts and latest message previews per channel
class UnreadMessagesState {
  final Map<String, int> channelUnreadCounts;
  final Map<String, String> channelLastMessages;
  final Map<String, String> channelLastSenders;
  final Map<String, DateTime> channelLastTimes;

  const UnreadMessagesState({
    this.channelUnreadCounts = const {},
    this.channelLastMessages = const {},
    this.channelLastSenders = const {},
    this.channelLastTimes = const {},
  });

  int get totalUnreadCount =>
      channelUnreadCounts.values.fold(0, (sum, count) => sum + count);

  int countForChannel(String channelId) => channelUnreadCounts[channelId] ?? 0;
  String? lastMessageForChannel(String channelId) => channelLastMessages[channelId];
  String? lastSenderForChannel(String channelId) => channelLastSenders[channelId];
  DateTime? lastTimeForChannel(String channelId) => channelLastTimes[channelId];

  UnreadMessagesState copyWith({
    Map<String, int>? channelUnreadCounts,
    Map<String, String>? channelLastMessages,
    Map<String, String>? channelLastSenders,
    Map<String, DateTime>? channelLastTimes,
  }) {
    return UnreadMessagesState(
      channelUnreadCounts: channelUnreadCounts ?? this.channelUnreadCounts,
      channelLastMessages: channelLastMessages ?? this.channelLastMessages,
      channelLastSenders: channelLastSenders ?? this.channelLastSenders,
      channelLastTimes: channelLastTimes ?? this.channelLastTimes,
    );
  }
}

class UnreadMessagesNotifier extends StateNotifier<UnreadMessagesState> {
  final Ref _ref;
  final SocketService _socketService;
  StreamSubscription? _subscription;
  final Set<String> _processedMessageKeys = {};

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

  void handleIncomingNotification(MessageNotification notif) {
    try {
      if (notif.channelId.isEmpty) return;

      final dedupKey = notif.messageId?.isNotEmpty == true
          ? notif.messageId!
          : '${notif.channelId}_${notif.content}_${notif.senderId}_${notif.createdAt.millisecondsSinceEpoch ~/ 1000}';

      if (_processedMessageKeys.contains(dedupKey)) {
        debugPrint('[UnreadMessagesNotifier] Skipping duplicate notification: $dedupKey');
        return;
      }
      _processedMessageKeys.add(dedupKey);
      if (_processedMessageKeys.length > 200) {
        _processedMessageKeys.remove(_processedMessageKeys.first);
      }

      final activeChannelId = _ref.read(activeChatChannelProvider);
      final isCurrentChannelOpen = (activeChannelId == notif.channelId);

      final updatedCounts = Map<String, int>.from(state.channelUnreadCounts);
      final updatedLastMessages = Map<String, String>.from(state.channelLastMessages);
      final updatedLastSenders = Map<String, String>.from(state.channelLastSenders);
      final updatedLastTimes = Map<String, DateTime>.from(state.channelLastTimes);

      // Instantly update card message preview & timestamp
      updatedLastMessages[notif.channelId] = notif.content;
      updatedLastSenders[notif.channelId] = notif.senderName;
      updatedLastTimes[notif.channelId] = notif.createdAt;

      // Only increment unread badge counters if user does NOT currently have this channel open
      if (!isCurrentChannelOpen) {
        updatedCounts[notif.channelId] = (updatedCounts[notif.channelId] ?? 0) + 1;
      }

      state = state.copyWith(
        channelUnreadCounts: updatedCounts,
        channelLastMessages: updatedLastMessages,
        channelLastSenders: updatedLastSenders,
        channelLastTimes: updatedLastTimes,
      );

      // Refresh workspace channels list to update preview and ordering in background
      if (notif.workspaceId.isNotEmpty) {
        _ref.invalidate(workspaceChannelsProvider(notif.workspaceId));
      }

      debugPrint(
        '[UnreadMessagesNotifier] Updated channel card for ${notif.channelId}: unread=${updatedCounts[notif.channelId]}, msg="${notif.content}"',
      );

      // Always show in-app banner toast for all incoming messages as requested
      InAppNotificationService.show(
        notif,
        onTap: (notification) => openChannelFromNotification(notification),
      );

      // LocalNotificationService is removed so only Firebase handles system status bar
    } catch (e) {
      debugPrint('[UnreadMessagesNotifier] Error handling notification: $e');
    }
  }

  void _handleIncomingNotification(Map<String, dynamic> data) {
    debugPrint('[UnreadMessagesNotifier] Received notification event: $data');
    final notif = MessageNotification.fromJson(data);
    handleIncomingNotification(notif);
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
