import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../auth/token_storage.dart';
import '../network/api_endpoints.dart';
import '../../app/router.dart';
import '../../features/chat/domain/models/channel_model.dart';
import '../../features/chat/domain/models/message_notification.dart';
import '../../features/chat/presentation/screens/channel_chat_screen.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (response.actionId == LocalNotificationService.replyActionId) {
    final text = response.input;
    final payload = response.payload;
    if (text != null && text.trim().isNotEmpty && payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final channelId = data['channelId'] as String?;
        if (channelId != null && channelId.isNotEmpty) {
          await LocalNotificationService.sendReply(channelId, text.trim());
          if (response.id != null) {
            final plugin = FlutterLocalNotificationsPlugin();
            await plugin.cancel(id: response.id!);
          }
        }
      } catch (e) {
        debugPrint('[LocalNotificationService] Background reply error: $e');
      }
    }
  }
}

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  static const String replyActionId = 'reply_action';
  static const String _channelId = 'teamflow_messages_channel';
  static const String _channelName = 'TeamFlow Messages';
  static const String _channelDesc = 'Incoming channel and direct messages';

  static Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwinCategories = <DarwinNotificationCategory>[
      DarwinNotificationCategory(
        'message_category',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.text(
            replyActionId,
            'Reply',
            buttonTitle: 'Send',
            placeholder: 'Type a reply...',
          ),
        ],
      ),
    ];

    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: darwinCategories,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create high-importance notification channel for Android status bar / heads-up notification
    final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidImpl.requestNotificationsPermission();
    }

    _isInitialized = true;
    debugPrint('[LocalNotificationService] System notification bar service initialized');
  }

  static Future<void> _onNotificationTapped(NotificationResponse response) async {
    // Handle inline direct reply action
    if (response.actionId == replyActionId) {
      final text = response.input;
      final payload = response.payload;
      if (text != null && text.trim().isNotEmpty && payload != null) {
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          final channelId = data['channelId'] as String?;
          if (channelId != null && channelId.isNotEmpty) {
            await sendReply(channelId, text.trim());
            if (response.id != null) {
              await _notificationsPlugin.cancel(id: response.id!);
            }
          }
        } catch (e) {
          debugPrint('[LocalNotificationService] Error sending direct reply: $e');
        }
      }
      return;
    }

    // Normal notification tap: open chat screen
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final notif = MessageNotification.fromJson(data);

      final navContext = rootNavigatorKey.currentContext;
      if (navContext == null) return;

      final channel = ChannelModel(
        id: notif.channelId,
        workspaceId: notif.workspaceId,
        name: notif.channelName,
        type: notif.isDM ? ChannelType.directMessage : ChannelType.public,
        updatedAt: notif.createdAt,
      );

      Navigator.of(navContext).push(
        MaterialPageRoute(
          builder: (_) => ChannelChatScreen(channel: channel),
        ),
      );
    } catch (e) {
      debugPrint('[LocalNotificationService] Error opening chat from notification bar: $e');
    }
  }

  static Future<void> sendReply(String channelId, String content) async {
    try {
      final tokenStorage = SecureTokenStorage();
      final token = await tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        debugPrint('[LocalNotificationService] No access token found to send reply');
        return;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      await dio.post(
        ApiEndpoints.channelSendMessage(channelId),
        data: {
          'content': content.trim(),
        },
      );
      debugPrint('[LocalNotificationService] Reply successfully sent to channel $channelId');
    } catch (e) {
      debugPrint('[LocalNotificationService] Failed to send reply: $e');
    }
  }

  static Future<void> showNotification(MessageNotification notification) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final isDM = notification.isDM;
      final title = isDM
          ? notification.senderName
          : '#${notification.channelName}';

      final body = isDM
          ? notification.content
          : '${notification.senderName}: ${notification.content}';

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.message,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: isDM ? 'Direct Message' : '#${notification.channelName}',
        ),
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            replyActionId,
            'Reply',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            inputs: <AndroidNotificationActionInput>[
              AndroidNotificationActionInput(
                label: 'Type a reply...',
              ),
            ],
            allowGeneratedReplies: true,
          ),
        ],
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'message_category',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final payload = jsonEncode({
        'channelId': notification.channelId,
        'channelName': notification.channelName,
        'isDM': notification.isDM,
        'senderId': notification.senderId,
        'senderName': notification.senderName,
        'senderEmail': notification.senderEmail,
        'content': notification.content,
        'taskId': notification.taskId,
        'taskTitle': notification.taskTitle,
        'workspaceId': notification.workspaceId,
        'createdAt': notification.createdAt.toIso8601String(),
      });

      final id = notification.channelId.hashCode;

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );

      debugPrint('[LocalNotificationService] Notification posted to system status bar with Reply action: $title');
    } catch (e) {
      debugPrint('[LocalNotificationService] Failed to post status bar notification: $e');
    }
  }
}
