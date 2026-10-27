import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../projects/presentation/providers/project_providers.dart';
import '../../../projects/presentation/widgets/create_project_dialog.dart';
import '../../../tasks/presentation/widgets/create_task_dialog.dart';
import '../../../workspaces/presentation/providers/workspace_providers.dart';
import '../../../workspaces/presentation/widgets/invite_member_dialog.dart';

class TeamQuickActionsSheet extends ConsumerWidget {
  final VoidCallback onStartDM;
  final VoidCallback onCreateChannel;

  const TeamQuickActionsSheet({
    super.key,
    required this.onStartDM,
    required this.onCreateChannel,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onStartDM,
    required VoidCallback onCreateChannel,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => TeamQuickActionsSheet(
        onStartDM: onStartDM,
        onCreateChannel: onCreateChannel,
      ),
    );
  }

  void _handleCreateTask(BuildContext context, WidgetRef ref, String workspaceId) async {
    Navigator.pop(context);
    final projects = await ref.read(workspaceProjectsProvider(workspaceId).future);
    if (!context.mounted) return;

    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a project first before adding tasks.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      CreateProjectDialog.show(context, workspaceId);
      return;
    }

    if (projects.length == 1) {
      CreateTaskDialog.show(
        context,
        projectId: projects.first.id,
        workspaceId: workspaceId,
      );
      return;
    }

    // Pick which project to create a task in
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Project for Task',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...projects.map((p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.folder_outlined, color: AppColors.primary),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${p.taskCount} active tasks'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      CreateTaskDialog.show(
                        context,
                        projectId: p.id,
                        workspaceId: workspaceId,
                      );
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceControllerProvider).currentWorkspace;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Create, connect, and collaborate with your team',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action 1: Start Direct Message
          _QuickActionTile(
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: const Color(0xFF6366F1),
            bgColor: const Color(0xFFEEF2FF),
            title: 'New Direct Message',
            subtitle: 'Start a 1-on-1 private chat with any team member',
            onTap: () {
              Navigator.pop(context);
              onStartDM();
            },
          ),
          const SizedBox(height: 10),

          // Action 2: Create Channel
          _QuickActionTile(
            icon: Icons.tag_rounded,
            iconColor: AppColors.primary,
            bgColor: AppColors.primary.withValues(alpha: 0.1),
            title: 'Create Channel',
            subtitle: 'Start a public or private team discussion channel',
            onTap: () {
              Navigator.pop(context);
              onCreateChannel();
            },
          ),
          const SizedBox(height: 10),

          // Action 3: Create Task
          if (workspace != null)
            _QuickActionTile(
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF059669),
              bgColor: const Color(0xFFD1FAE5),
              title: 'Create Task',
              subtitle: 'Add a new task with priority, assignee, and due date',
              onTap: () => _handleCreateTask(context, ref, workspace.id),
            ),
          if (workspace != null) const SizedBox(height: 10),

          // Action 4: Create Project
          if (workspace != null && workspace.role.isManagerOrAbove)
            _QuickActionTile(
              icon: Icons.dashboard_customize_outlined,
              iconColor: const Color(0xFFD97706),
              bgColor: const Color(0xFFFEF3C7),
              title: 'New Project',
              subtitle: 'Set up a new project board with Kanban workflow',
              onTap: () {
                Navigator.pop(context);
                CreateProjectDialog.show(context, workspace.id);
              },
            ),
          if (workspace != null && workspace.role.isManagerOrAbove)
            const SizedBox(height: 10),

          // Action 5: Invite Member
          if (workspace != null && workspace.role.isManagerOrAbove)
            _QuickActionTile(
              icon: Icons.person_add_outlined,
              iconColor: AppColors.primary,
              bgColor: const Color(0xFFEBE5C2),
              title: 'Invite Team Member',
              subtitle: 'Add colleagues to your workspace via email or invite code',
              onTap: () {
                Navigator.pop(context);
                InviteMemberDialog.show(context, workspace.id);
              },
            ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
