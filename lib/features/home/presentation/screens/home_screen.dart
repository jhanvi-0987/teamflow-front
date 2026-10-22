import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../workspaces/presentation/providers/workspace_providers.dart';
import '../../../workspaces/presentation/widgets/workspace_switcher_sheet.dart';
import '../../../workspaces/presentation/widgets/create_workspace_dialog.dart';
import '../../../workspaces/presentation/widgets/accept_invite_dialog.dart';
import '../../../workspaces/presentation/widgets/invite_member_dialog.dart';
import '../../../workspaces/presentation/screens/workspace_settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workspaceControllerProvider.notifier).loadWorkspaces();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final workspaceState = ref.watch(workspaceControllerProvider);
    final currentWorkspace = workspaceState.currentWorkspace;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => WorkspaceSwitcherSheet.show(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentWorkspace?.name ?? 'Select Workspace',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
        actions: [
          if (currentWorkspace != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Workspace Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WorkspaceSettingsScreen(
                      workspaceId: currentWorkspace.id,
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: workspaceState.isLoading && workspaceState.workspaces.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(workspaceControllerProvider.notifier)
                    .loadWorkspaces();
              },
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  // User greeting
                  Text(
                    'Hello, ${user?.name ?? 'Teammate'} 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (currentWorkspace == null) ...[
                    // Empty state: no workspace
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.business_outlined,
                                color: AppColors.primary,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Active Workspace',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create a new workspace or join an existing team using an invitation token.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 20),
                            AppButton(
                              text: 'Create Workspace',
                              icon: Icons.add,
                              onPressed: () =>
                                  CreateWorkspaceDialog.show(context),
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              text: 'Join with Token',
                              isSecondary: true,
                              icon: Icons.mail_outline,
                              onPressed: () =>
                                  AcceptInviteDialog.show(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Active Workspace Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primary,
                                      child: Text(
                                        currentWorkspace.name
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentWorkspace.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'slug: ${currentWorkspace.slug}',
                                          style: const TextStyle(
                                            color: AppColors.darkTextSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    currentWorkspace.role.displayName
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 28),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetric(
                                  icon: Icons.people_outline,
                                  label: 'Members',
                                  value:
                                      '${currentWorkspace.memberCount}',
                                ),
                                _buildMetric(
                                  icon: Icons.folder_outlined,
                                  label: 'Projects',
                                  value:
                                      '${currentWorkspace.projectCount}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Actions
                    const Text(
                      'Workspace Actions',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (currentWorkspace.role.isAdminOrAbove)
                          Expanded(
                            child: AppButton(
                              text: 'Invite Member',
                              icon: Icons.person_add_outlined,
                              onPressed: () => InviteMemberDialog.show(
                                  context, currentWorkspace.id),
                            ),
                          ),
                        if (currentWorkspace.role.isAdminOrAbove)
                          const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            text: 'Settings',
                            isSecondary: true,
                            icon: Icons.settings_outlined,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      WorkspaceSettingsScreen(
                                    workspaceId: currentWorkspace.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'Switch Workspace',
                      isSecondary: true,
                      icon: Icons.swap_horiz,
                      onPressed: () => WorkspaceSwitcherSheet.show(context),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Card(
                    color: AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border, width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.success, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Phase 2 Complete: Multi-tenant Workspaces, RBAC, and Hashed Invitations active.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.darkTextSecondary),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.darkTextSecondary,
          ),
        ),
      ],
    );
  }
}
