import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/notifications/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await LocalNotificationService.initialize();
  } catch (e) {
    debugPrint('[Main] Notification service init warning: $e');
  }
  runApp(
    const ProviderScope(
      child: TeamFlowApp(),
    ),
  );
}
