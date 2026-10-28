import 'dart:convert';
import 'dart:io';
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
      await LocalNotificationService.processDirectReply(
        notificationId: response.id ?? 0,
        replyText: text.trim(),
        payloadString: payload,
      );
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
        await processDirectReply(
          notificationId: response.id ?? 0,
          replyText: text.trim(),
          payloadString: payload,
        );
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

  /// Sends the reply message directly via HTTP and clears Android's RemoteInput spinner
  static Future<void> processDirectReply({
    required int notificationId,
    required String replyText,
    required String payloadString,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();
    String? channelId;
    String? title;

    try {
      final data = jsonDecode(payloadString) as Map<String, dynamic>;
      channelId = data['channelId'] as String?;
      final isDM = data['isDM'] == true || data['isDM'] == 'true';
      title = isDM
          ? (data['senderName'] as String? ?? 'Direct Message')
          : '#${data['channelName'] ?? 'channel'}';

      String? token = data['accessToken'] as String?;
      if (token == null || token.isEmpty) {
        try {
          final tokenStorage = SecureTokenStorage();
          token = await tokenStorage.getAccessToken();
        } catch (_) {}
      }

      String baseUrl = data['baseUrl'] as String? ?? ApiEndpoints.baseUrl;

      if (channelId != null && channelId.isNotEmpty && token != null && token.isNotEmpty) {
        // Send using standard dart:io HttpClient (independent of Flutter plugin engine)
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        final normalizedBase = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
        final uri = Uri.parse('$normalizedBase/channels/$channelId/messages');
        final request = await client.postUrl(uri);
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        request.add(utf8.encode(jsonEncode({'content': replyText})));
        final httpResponse = await request.close();
        client.close();
        debugPrint('[LocalNotificationService] Direct reply HTTP response: ${httpResponse.statusCode}');
      } else {
        debugPrint('[LocalNotificationService] Missing channelId or token for direct reply');
      }
    } catch (e) {
      debugPrint('[LocalNotificationService] Direct reply error: $e');
    } finally {
      // CLEAR THE LOADING SPINNER:
      // Re-posting on the same ID immediately tells Android OS that the RemoteInput is completed,
      // which clears the spinner and displays the confirmation.
      try {
        const androidDetails = AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          autoCancel: true,
          icon: '@mipmap/ic_launcher',
        );
        await plugin.show(
          id: notificationId,
          title: title ?? 'TeamFlow',
          body: '✓ Sent: $replyText',
          notificationDetails: const NotificationDetails(android: androidDetails),
        );
        // Automatically dismiss the confirmation after 1.5 seconds
        Future.delayed(const Duration(milliseconds: 1500), () {
          plugin.cancel(id: notificationId).catchError((_) {});
        });
      } catch (e) {
        plugin.cancel(id: notificationId).catchError((_) {});
      }
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
            cancelNotification: false,
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

      // Embed current access token & base URL so background isolates can dispatch directly
      String? token;
      try {
        token = await SecureTokenStorage().getAccessToken();
      } catch (_) {}

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
        'accessToken': token ?? '',
        'baseUrl': ApiEndpoints.baseUrl,
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
