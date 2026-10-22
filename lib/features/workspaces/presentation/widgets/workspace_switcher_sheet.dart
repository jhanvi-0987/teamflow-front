import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/workspace_providers.dart';
import 'create_workspace_dialog.dart';
import 'accept_invite_dialog.dart';

class WorkspaceSwitcherSheet extends ConsumerWidget {
  const WorkspaceSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.border, width: 1.2),
      ),
      builder: (context) => const WorkspaceSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceControllerProvider);
    final activeWorkspace = workspaceState.currentWorkspace;
    final workspaces = workspaceState.workspaces;

    return SafeArea(
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
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Workspaces',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    CreateWorkspaceDialog.show(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (workspaces.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No workspaces yet. Create one or join with an invite.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: workspaces.length,
                  separatorBuilder: (_, index) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final ws = workspaces[index];
                    final isSelected = ws.id == activeWorkspace?.id;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        child: Text(
                          ws.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.background
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        ws.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Role: ${ws.role.displayName} • ${ws.memberCount} members',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: AppColors.primary, size: 20)
                          : null,
                      onTap: () {
                        ref
                            .read(workspaceControllerProvider.notifier)
                            .switchWorkspace(ws);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Join with Invitation Token',
              icon: Icons.mail_outline,
              isSecondary: true,
              onPressed: () {
                Navigator.of(context).pop();
                AcceptInviteDialog.show(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
