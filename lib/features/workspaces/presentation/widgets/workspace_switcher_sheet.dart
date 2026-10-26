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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const WorkspaceSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceControllerProvider);
    final activeWorkspace = workspaceState.currentWorkspace;
    final workspaces = workspaceState.workspaces;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title bar with "New Workspace" action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.corporate_fare_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workspaces',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Switch or join another workspace',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'New',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      CreateWorkspaceDialog.show(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (workspaces.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.apartment_rounded, size: 36, color: AppColors.textSecondary),
                        const SizedBox(height: 10),
                        const Text(
                          'No workspaces found',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a new workspace or paste an invitation token.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: workspaces.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final ws = workspaces[index];
                      final isSelected = ws.id == activeWorkspace?.id;

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          ref
                              .read(workspaceControllerProvider.notifier)
                              .switchWorkspace(ws);
                          Navigator.of(context).pop();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : AppColors.surfaceVariant.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border.withValues(alpha: 0.5),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? AppColors.primaryGradient
                                      : null,
                                  color: isSelected
                                      ? null
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Center(
                                  child: Text(
                                    ws.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            ws.name,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              fontSize: 14.5,
                                              color: AppColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            ws.role.displayName,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${ws.memberCount} ${ws.memberCount == 1 ? 'member' : 'members'} • ${ws.projectCount} ${ws.projectCount == 1 ? 'project' : 'projects'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 18),

              // Join with invitation token button
              AppButton(
                text: 'Join with Invitation Token',
                icon: Icons.vpn_key_outlined,
                isSecondary: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  AcceptInviteDialog.show(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
