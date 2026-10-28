import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../workspaces/presentation/widgets/accept_invite_dialog.dart';
import '../../domain/models/app_notification.dart';
import '../providers/notifications_providers.dart';

class NotificationCenterDrawer extends ConsumerWidget {
  const NotificationCenterDrawer({super.key});

  /// Opens the Notification Center as a high-end sliding drawer from the right
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim1, anim2) {
        return const NotificationCenterDrawer();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedAnimation = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsNotifierProvider);
    final notifier = ref.read(notificationsNotifierProvider.notifier);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final drawerWidth = screenWidth > 600 ? 460.0 : (screenWidth * 0.92);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: drawerWidth,
          height: mediaQuery.size.height,
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 32,
                offset: const Offset(-8, 0),
              ),
            ],
            border: Border(
              left: BorderSide(
                color: AppColors.border.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header with Drawer Controls
                _buildHeader(context, ref, state),

                // Category Filter Bar
                _buildFilterBar(ref, state),

                const Divider(height: 1, color: AppColors.divider),

                // Notification Feed List
                Expanded(
                  child: state.isLoading && state.items.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () => notifier.refresh(),
                          child: state.filteredItems.isEmpty
                              ? _buildEmptyState(state.activeCategory)
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                                  itemCount: state.filteredItems.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final notif = state.filteredItems[index];
                                    return _NotificationItemCard(
                                      notification: notif,
                                      onTap: () => _handleDeepLink(context, ref, notif),
                                      onMarkRead: () =>
                                          notifier.markAsRead(notif.id),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    NotificationsState state,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activity Feed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.unreadCount > 0
                          ? '${state.unreadCount} unread update${state.unreadCount == 1 ? '' : 's'}'
                          : 'All caught up',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: state.unreadCount > 0
                            ? const Color(0xFFDC2626)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Close Drawer Button
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                color: AppColors.textSecondary,
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: state.unreadCount > 0
                            ? const Color(0xFF10B981)
                            : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Live Socket Sync',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // "Mark all as read" Action Button
              if (state.unreadCount > 0)
                InkWell(
                  onTap: () {
                    ref.read(notificationsNotifierProvider.notifier).markAllAsRead();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.done_all_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Mark all as read',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(WidgetRef ref, NotificationsState state) {
    final filters = [
      (NotificationCategory.all, 'All', Icons.dynamic_feed_rounded),
      (NotificationCategory.unread, 'Unread', Icons.fiber_manual_record_rounded),
      (NotificationCategory.tasks, 'Tasks', Icons.assignment_turned_in_rounded),
      (NotificationCategory.mentions, 'Mentions', Icons.alternate_email_rounded),
      (NotificationCategory.invites, 'Invites', Icons.mail_outline_rounded),
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = state.activeCategory == filter.$1;

          return InkWell(
            onTap: () {
              ref
                  .read(notificationsNotifierProvider.notifier)
                  .setCategory(filter.$1);
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter.$3,
                    size: 14,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (filter.$1 == NotificationCategory.unread &&
                      state.unreadCount > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${state.unreadCount}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? AppColors.primary : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(NotificationCategory category) {
    String message = "You're all caught up!";
    String subMessage = 'No new activity in your workspace.';
    IconData icon = Icons.check_circle_outline_rounded;

    if (category == NotificationCategory.unread) {
      message = 'No unread notifications';
      subMessage = 'Great job! You have addressed all updates.';
      icon = Icons.mark_chat_read_outlined;
    } else if (category == NotificationCategory.mentions) {
      message = 'No mentions yet';
      subMessage = 'When someone tags you in a task or comment, it will appear here.';
      icon = Icons.alternate_email_rounded;
    } else if (category == NotificationCategory.tasks) {
      message = 'No task updates';
      subMessage = 'Task assignments and status changes will be logged here.';
      icon = Icons.task_alt_rounded;
    } else if (category == NotificationCategory.invites) {
      message = 'No pending invites';
      subMessage = 'Workspace invitations sent to you will appear here.';
      icon = Icons.mark_email_read_outlined;
    }

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, size: 36, color: AppColors.primaryLight),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subMessage,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeepLink(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    // 1. Mark as read
    if (!notification.isRead) {
      ref
          .read(notificationsNotifierProvider.notifier)
          .markAsRead(notification.id);
    }

    // 2. Dismiss drawer
    Navigator.of(context).pop();

    // 3. Deep-link based on payload
    if (notification.taskId != null && notification.taskId!.isNotEmpty) {
      context.push('/tasks/${notification.taskId}');
      return;
    }

    if (notification.projectId != null && notification.projectId!.isNotEmpty) {
      context.push('/projects/${notification.projectId}');
      return;
    }

    if (notification.type.toUpperCase() == 'WORKSPACE_INVITATION') {
      AcceptInviteDialog.show(context, initialToken: notification.inviteToken);
      return;
    }
  }
}

class _NotificationItemCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  const _NotificationItemCard({
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final catColor = notification.categoryColor;

    return Container(
      decoration: BoxDecoration(
        color: isUnread
            ? Colors.white
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? catColor.withValues(alpha: 0.45)
              : AppColors.border.withValues(alpha: 0.25),
          width: isUnread ? 1.4 : 1.0,
        ),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: catColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon Badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: catColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    notification.iconData,
                    size: 20,
                    color: catColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Notification Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Type title + Time + Unread indicator
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: catColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            notification.relativeTime,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: catColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: catColor.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Notification message
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Context / Resource Chips (Task Title, Project, Workspace)
                      if (notification.taskTitle != null ||
                          notification.projectName != null ||
                          notification.workspaceName != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (notification.taskTitle != null)
                              _ResourceChip(
                                icon: Icons.task_alt_rounded,
                                label: notification.taskTitle!,
                                color: const Color(0xFFD97706),
                              ),
                            if (notification.projectName != null)
                              _ResourceChip(
                                icon: Icons.folder_outlined,
                                label: notification.projectName!,
                                color: AppColors.primary,
                              ),
                            if (notification.workspaceName != null &&
                                notification.taskTitle == null)
                              _ResourceChip(
                                icon: Icons.domain_rounded,
                                label: notification.workspaceName!,
                                color: const Color(0xFF2563EB),
                              ),
                          ],
                        ),
                      ],

                      // Deep Link Hint Row
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                _getDeepLinkActionText(notification),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                          if (isUnread)
                            InkWell(
                              onTap: onMarkRead,
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Mark read',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDeepLinkActionText(AppNotification n) {
    if (n.taskId != null) return 'View task';
    if (n.projectId != null) return 'View project';
    if (n.type.toUpperCase() == 'WORKSPACE_INVITATION') return 'Accept invitation';
    return 'View details';
  }
}

class _ResourceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ResourceChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
