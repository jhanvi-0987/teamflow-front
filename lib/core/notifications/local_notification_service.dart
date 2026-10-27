import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../app/router.dart';
import '../../features/chat/domain/models/channel_model.dart';
import '../../features/chat/domain/models/message_notification.dart';
import '../../features/chat/presentation/screens/channel_chat_screen.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  static const String _channelId = 'teamflow_messages_channel';
  static const String _channelName = 'TeamFlow Messages';
  static const String _channelDesc = 'Incoming channel and direct messages';

  static Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create high-importance notification channel for Android status bar
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

  static void _onNotificationTapped(NotificationResponse response) {
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

  static Future<void> showNotification(MessageNotification notification) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final isDM = notification.isDM;
      final title = isDM
          ? notification.senderName
          : '${notification.senderName} (#${notification.channelName})';

      final body = notification.content;

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: const Color(0xFF504B38),
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: isDM ? 'Direct Message' : '#${notification.channelName}',
        ),
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
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

      debugPrint('[LocalNotificationService] Notification posted to system status bar: $title');
    } catch (e) {
      debugPrint('[LocalNotificationService] Failed to post status bar notification: $e');
    }
  }
}
