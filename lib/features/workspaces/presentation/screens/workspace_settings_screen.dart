import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/workspace.dart';
import '../providers/workspace_providers.dart';
import '../widgets/invite_member_dialog.dart';

class WorkspaceSettingsScreen extends ConsumerWidget {
  final String workspaceId;

  const WorkspaceSettingsScreen({super.key, required this.workspaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceControllerProvider);
    final workspace = workspaceState.workspaces
        .where((w) => w.id == workspaceId)
        .firstOrNull ??
        workspaceState.currentWorkspace;

    if (workspace == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text('Workspace Settings'),
        ),
        body: const Center(child: Text('Workspace not found')),
      );
    }

    final membersAsync = ref.watch(workspaceMembersProvider(workspaceId));
    final invitationsAsync =
        ref.watch(workspaceInvitationsProvider(workspaceId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              workspace.role.isAdminOrAbove
                  ? 'Admin Dashboard'
                  : 'Workspace Info',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            if (workspace.role.isAdminOrAbove) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  workspace.role.displayName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (workspace.role.isAdminOrAbove)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => InviteMemberDialog.show(context, workspaceId),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_add_outlined,
                            size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Invite',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Workspace Info Card
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      workspace.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspace.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              workspace.slug,
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    AppColors.textMuted.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              workspace.role.displayName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
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
          const SizedBox(height: 28),

          // Members Section
          _buildSectionHeader(
            icon: Icons.people_outline_rounded,
            title: 'Members',
            trailing: workspace.role.isAdminOrAbove
                ? GestureDetector(
                    onTap: () =>
                        InviteMemberDialog.show(context, workspaceId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded,
                              size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          membersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Error loading members: $err',
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
            data: (members) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.3)),
                  boxShadow: AppColors.cardShadow,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (_, index) => Divider(
                    height: 1,
                    color: AppColors.border.withValues(alpha: 0.3),
                    indent: 68,
                  ),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                member.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        member.email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted
                                              .withValues(alpha: 0.7),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        member.role.displayName,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (workspace.role.isOwner &&
                              !member.role.isOwner)
                            PopupMenuButton<String>(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.more_horiz_rounded,
                                    size: 16, color: AppColors.textSecondary),
                              ),
                              onSelected: (action) async {
                                if (action == 'remove') {
                                  await ref
                                      .read(workspacesRepositoryProvider)
                                      .removeMember(
                                          workspaceId, member.userId);
                                  ref.invalidate(workspaceMembersProvider(
                                      workspaceId));
                                } else if (action == 'make_admin') {
                                  await ref
                                      .read(workspacesRepositoryProvider)
                                      .updateMemberRole(workspaceId,
                                          member.userId, WorkspaceRole.admin);
                                  ref.invalidate(workspaceMembersProvider(
                                      workspaceId));
                                } else if (action == 'make_member') {
                                  await ref
                                      .read(workspacesRepositoryProvider)
                                      .updateMemberRole(
                                          workspaceId,
                                          member.userId,
                                          WorkspaceRole.member);
                                  ref.invalidate(workspaceMembersProvider(
                                      workspaceId));
                                }
                              },
                              itemBuilder: (context) => [
                                if (member.role != WorkspaceRole.admin)
                                  const PopupMenuItem(
                                    value: 'make_admin',
                                    child: Row(
                                      children: [
                                        Icon(Icons.shield_outlined,
                                            size: 16,
                                            color: AppColors.primary),
                                        SizedBox(width: 8),
                                        Text('Promote to Admin'),
                                      ],
                                    ),
                                  ),
                                if (member.role != WorkspaceRole.member)
                                  const PopupMenuItem(
                                    value: 'make_member',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_outline,
                                            size: 16,
                                            color: AppColors.textSecondary),
                                        SizedBox(width: 8),
                                        Text('Change to Member'),
                                      ],
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Row(
                                    children: [
                                      Icon(Icons.remove_circle_outline,
                                          size: 16, color: AppColors.error),
                                      SizedBox(width: 8),
                                      Text('Remove Member',
                                          style:
                                              TextStyle(color: AppColors.error)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // Pending Invitations (for Admin and Owner)
          if (workspace.role.isAdminOrAbove) ...[
            _buildSectionHeader(
              icon: Icons.mail_outline_rounded,
              title: 'Pending Invitations',
            ),
            const SizedBox(height: 12),
            invitationsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('Error loading invites: $err',
                    style: const TextStyle(color: AppColors.error)),
              ),
              data: (invites) {
                if (invites.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 18,
                            color: AppColors.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(width: 8),
                        Text(
                          'No pending invitations',
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.3)),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invites.length,
                    separatorBuilder: (_, index) => Divider(
                      height: 1,
                      color: AppColors.border.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) {
                      final inv = invites[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.accent
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.mail_outline_rounded,
                                  color: AppColors.accent, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inv.email,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Role: ${inv.role.displayName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                await ref
                                    .read(workspacesRepositoryProvider)
                                    .revokeInvitation(workspaceId, inv.id);
                                ref.invalidate(
                                    workspaceInvitationsProvider(
                                        workspaceId));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.errorLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.close_rounded,
                                    color: AppColors.error, size: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
          ],

          // Danger Zone
          _buildSectionHeader(
            icon: Icons.warning_amber_rounded,
            title: 'Danger Zone',
            iconColor: AppColors.error,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (workspace.role.isOwner)
                  AppButton(
                    text: 'Archive Workspace',
                    isSecondary: true,
                    isDanger: true,
                    icon: Icons.archive_outlined,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Archive Workspace?',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          content: const Text(
                            'Are you sure? Projects will be placed in read-only mode.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                minimumSize: const Size(0, 42),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Archive',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(workspaceControllerProvider.notifier)
                            .archiveWorkspace(workspaceId);
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    },
                  )
                else
                  AppButton(
                    text: 'Leave Workspace',
                    isSecondary: true,
                    isDanger: true,
                    icon: Icons.exit_to_app_rounded,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Leave Workspace?',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          content: const Text(
                            'Are you sure you want to leave this workspace?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                minimumSize: const Size(0, 42),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Leave',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(workspaceControllerProvider.notifier)
                            .leaveWorkspace(workspaceId);
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? iconColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  size: 16, color: iconColor ?? AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        ?trailing,
      ],
    );
  }
}
