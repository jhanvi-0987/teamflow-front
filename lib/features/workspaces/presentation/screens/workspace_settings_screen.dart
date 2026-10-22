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
        appBar: AppBar(title: const Text('Workspace Settings')),
        body: const Center(child: Text('Workspace not found')),
      );
    }

    final membersAsync = ref.watch(workspaceMembersProvider(workspaceId));
    final invitationsAsync =
        ref.watch(workspaceInvitationsProvider(workspaceId));

    return Scaffold(
      appBar: AppBar(
        title: Text('${workspace.name} Settings'),
        actions: [
          if (workspace.role.isAdminOrAbove)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Invite Member',
              onPressed: () => InviteMemberDialog.show(context, workspaceId),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Workspace Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          workspace.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workspace.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'slug: ${workspace.slug} • Your role: ${workspace.role.displayName}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Members Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Members',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (workspace.role.isAdminOrAbove)
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Invite'),
                  onPressed: () =>
                      InviteMemberDialog.show(context, workspaceId),
                ),
            ],
          ),
          const SizedBox(height: 8),
          membersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Text(
              'Error loading members: $err',
              style: const TextStyle(color: AppColors.error),
            ),
            data: (members) {
              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.darkBackground,
                        child: Text(
                          member.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                      ),
                      title: Text(member.name),
                      subtitle: Text(
                        '${member.email} • ${member.role.displayName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                      trailing: workspace.role.isOwner && !member.role.isOwner
                          ? PopupMenuButton<String>(
                              onSelected: (action) async {
                                if (action == 'remove') {
                                  await ref
                                      .read(workspacesRepositoryProvider)
                                      .removeMember(
                                          workspaceId, member.userId);
                                  ref.invalidate(
                                      workspaceMembersProvider(workspaceId));
                                } else if (action == 'make_admin') {
                                  await ref
                                      .read(workspacesRepositoryProvider)
                                      .updateMemberRole(
                                          workspaceId,
                                          member.userId,
                                          WorkspaceRole.admin);
                                  ref.invalidate(
                                      workspaceMembersProvider(workspaceId));
                                } else if (action == 'make_member') {
                                  await ref
                                      .read(workspacesRepositoryProvider)
                                      .updateMemberRole(
                                          workspaceId,
                                          member.userId,
                                          WorkspaceRole.member);
                                  ref.invalidate(
                                      workspaceMembersProvider(workspaceId));
                                }
                              },
                              itemBuilder: (context) => [
                                if (member.role != WorkspaceRole.admin)
                                  const PopupMenuItem(
                                    value: 'make_admin',
                                    child: Text('Promote to Admin'),
                                  ),
                                if (member.role != WorkspaceRole.member)
                                  const PopupMenuItem(
                                    value: 'make_member',
                                    child: Text('Change to Member'),
                                  ),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Text('Remove Member',
                                      style: TextStyle(color: AppColors.error)),
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Pending Invitations (for Admin and Owner)
          if (workspace.role.isAdminOrAbove) ...[
            const Text(
              'Pending Invitations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            invitationsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Text('Error loading invites: $err'),
              data: (invites) {
                if (invites.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No pending invitations',
                        style: TextStyle(color: AppColors.darkTextSecondary),
                      ),
                    ),
                  );
                }
                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invites.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final inv = invites[index];
                      return ListTile(
                        leading: const Icon(Icons.mail_outline,
                            color: AppColors.accent),
                        title: Text(inv.email),
                        subtitle: Text(
                          'Role: ${inv.role.displayName}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: AppColors.error),
                          tooltip: 'Revoke',
                          onPressed: () async {
                            await ref
                                .read(workspacesRepositoryProvider)
                                .revokeInvitation(workspaceId, inv.id);
                            ref.invalidate(
                                workspaceInvitationsProvider(workspaceId));
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // Danger Zone / Workspace Actions
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.error, width: 0.8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workspace Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (workspace.role.isOwner)
                    AppButton(
                      text: 'Archive Workspace',
                      isSecondary: true,
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.darkSurface,
                            title: const Text('Archive Workspace?'),
                            content: const Text(
                              'Are you sure you want to archive this workspace? Projects will be placed in read-only mode.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Archive',
                                    style: TextStyle(color: AppColors.error)),
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
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.darkSurface,
                            title: const Text('Leave Workspace?'),
                            content: const Text(
                              'Are you sure you want to leave this workspace?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Leave',
                                    style: TextStyle(color: AppColors.error)),
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
          ),
        ],
      ),
    );
  }
}
