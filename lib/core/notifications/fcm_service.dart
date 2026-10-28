import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/router.dart';
import '../../features/chat/domain/models/channel_model.dart';
import '../../features/chat/domain/models/message_notification.dart';
import '../../features/chat/presentation/providers/chat_notification_providers.dart';
import '../../features/chat/presentation/screens/channel_chat_screen.dart';
import '../network/api_client.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('[FCM Background] Handling background message: ${message.messageId}');
  } catch (e) {
    debugPrint('[FCM Background] Error in background handler: $e');
  }
}

class FcmService {
  final ApiClient _apiClient;
  final Ref _ref;
  bool _isInitialized = false;

  FcmService({
    required ApiClient apiClient,
    required Ref ref,
  })  : _apiClient = apiClient,
        _ref = ref;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      // Register device token with backend
      await _syncToken();

      // Listen for token updates
      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        _registerTokenOnBackend(newToken);
      });

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // Handle notification tap when app opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message.data);
      });

      // Check if launched from a notification (cold start)
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage.data);
      }

      _isInitialized = true;
      debugPrint('[FCM] Initialized successfully');
    } catch (e) {
      debugPrint('[FCM] Initialization warning (waiting for valid setup): $e');
    }
  }

  Future<void> _syncToken() async {
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('[FCM] Device Token: $token');
        await _registerTokenOnBackend(token);
      }
    } catch (e) {
      debugPrint('[FCM] Failed to retrieve FCM device token: $e');
    }
  }

  Future<void> _registerTokenOnBackend(String token) async {
    try {
      await _apiClient.dio.post(
        '/notifications/fcm-token',
        data: {
          'token': token,
          'platform': 'android',
        },
      );
      debugPrint('[FCM] Registered token on backend successfully');
    } catch (e) {
      debugPrint('[FCM] Failed to send token to backend: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message received: ${message.data}');
    final data = message.data;
    if (data.isEmpty) return;

    final notif = MessageNotification(
      messageId: data['messageId'] ?? message.messageId,
      channelId: data['channelId'] ?? '',
      channelName: data['channelName'] ?? 'General',
      isDM: data['isDM'] == 'true' || data['isDM'] == true,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? message.notification?.title ?? 'Teammate',
      senderEmail: data['senderEmail'] ?? '',
      content: data['content'] ?? message.notification?.body ?? '',
      taskId: data['taskId'],
      taskTitle: data['taskTitle'],
      workspaceId: data['workspaceId'] ?? '',
      createdAt: DateTime.now(),
    );

    // Update unread card counter, message preview, and display banner
    _ref.read(unreadMessagesProvider.notifier).handleIncomingNotification(notif);
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    final channelId = data['channelId'] as String?;
    if (channelId == null || channelId.isEmpty) return;

    final notif = MessageNotification(
      channelId: channelId,
      channelName: data['channelName'] ?? 'Chat',
      isDM: data['isDM'] == 'true' || data['isDM'] == true,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Teammate',
      senderEmail: data['senderEmail'] ?? '',
      content: data['content'] ?? '',
      taskId: data['taskId'],
      taskTitle: data['taskTitle'],
      workspaceId: data['workspaceId'] ?? '',
      createdAt: DateTime.now(),
    );

    _openChat(notif);
  }

  void _openChat(MessageNotification notification) {
    _ref.read(unreadMessagesProvider.notifier).markChannelAsRead(notification.channelId);

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
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FcmService(apiClient: apiClient, ref: ref);
});
