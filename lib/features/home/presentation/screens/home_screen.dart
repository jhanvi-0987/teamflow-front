import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/fcm_service.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../chat/presentation/providers/chat_notification_providers.dart';
import '../../../chat/presentation/screens/channels_list_screen.dart';
import '../../../workspaces/presentation/providers/workspace_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/quick_actions_sheet.dart';
import 'activity_tab_view.dart';
import 'projects_tab_view.dart';
import 'workspace_tab_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Home screen is ALWAYS Tab 0 (Team Chat Hub) as requested!
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socketServiceProvider).connect();
      ref.read(fcmServiceProvider).initialize();
      ref.read(workspaceControllerProvider.notifier).loadWorkspaces();
      ref.read(notificationsNotifierProvider.notifier).loadNotifications();
    });
  }

  void _openQuickActions() {
    TeamQuickActionsSheet.show(
      context,
      onStartDM: () {
        // Switch to Chat tab to see/start DMs
        setState(() => _currentIndex = 0);
      },
      onCreateChannel: () {
        // Switch to Chat tab to see/create channels
        setState(() => _currentIndex = 0);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadState = ref.watch(unreadMessagesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // IndexedStack preserves state, active chats, and scroll positions across all tabs
          IndexedStack(
            index: _currentIndex,
            children: const [
              ChannelsListScreen(), // Option 0: Chat Hub (Always Home Screen!)
              ProjectsTabView(),    // Option 1: Kanban & Project Boards
              ActivityTabView(),    // Option 2: Live Activity & Pulse
              WorkspaceTabView(),   // Option 3: Workspace, Members & Settings
            ],
          ),

          // Floating Glassmorphic Bottom Navigation Bar with Quick Actions Hub
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavBar(
              selectedIndex: _currentIndex,
              chatBadgeCount: unreadState.totalUnreadCount,
              onItemSelected: (index) {
                setState(() => _currentIndex = index);
              },
              onQuickActionTap: _openQuickActions,
            ),
          ),
        ],
      ),
    );
  }
}
