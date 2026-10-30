import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../features/chat/presentation/providers/call_providers.dart';
import '../features/chat/presentation/widgets/incoming_call_dialog.dart';
import 'router.dart';

class TeamFlowApp extends ConsumerWidget {
  const TeamFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Listen globally for incoming calls across all screens
    ref.listen<CallState>(callStateProvider, (prev, next) {
      if (prev?.uiStatus != CallUIStatus.incomingRinging &&
          next.uiStatus == CallUIStatus.incomingRinging) {
        final navContext = rootNavigatorKey.currentContext;
        if (navContext != null) {
          showDialog(
            context: navContext,
            barrierDismissible: false,
            builder: (_) => const IncomingCallDialog(),
          );
        }
      }
    });

    return MaterialApp.router(
      title: 'TeamFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
