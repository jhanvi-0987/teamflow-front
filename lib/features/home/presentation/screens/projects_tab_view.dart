import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../projects/domain/models/project.dart';
import '../../../projects/presentation/providers/project_providers.dart';
import '../../../projects/presentation/widgets/create_project_dialog.dart';
import '../../../projects/presentation/widgets/project_card.dart';
import '../../../workspaces/domain/models/workspace.dart';
import '../../../workspaces/presentation/providers/workspace_providers.dart';
import '../../../workspaces/presentation/screens/workspace_settings_screen.dart';
import '../../../workspaces/presentation/widgets/accept_invite_dialog.dart';
import '../../../workspaces/presentation/widgets/create_workspace_dialog.dart';
import '../../../workspaces/presentation/widgets/invite_member_dialog.dart';
import '../../../workspaces/presentation/widgets/workspace_switcher_sheet.dart';
import '../../../notifications/presentation/widgets/notification_bell_button.dart';

class ProjectsTabView extends ConsumerWidget {
  const ProjectsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceControllerProvider);
    final currentWorkspace = workspaceState.currentWorkspace;
    final projectsAsync = currentWorkspace != null
        ? ref.watch(workspaceProjectsProvider(currentWorkspace.id))
        : null;

    if (currentWorkspace == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildEmptyWorkspaceState(context),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: currentWorkspace.role.isManagerOrAbove
          ? Container(
              margin: const EdgeInsets.only(bottom: 70),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.buttonShadow,
              ),
              child: FloatingActionButton.extended(
                onPressed: () => CreateProjectDialog.show(
                  context,
                  currentWorkspace.id,
                ),
                backgroundColor: AppColors.primary,
                elevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'New Project',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(workspaceControllerProvider.notifier).loadWorkspaces();
          ref.invalidate(workspaceProjectsProvider(currentWorkspace.id));
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.background.withValues(alpha: 0.95),
              surfaceTintColor: Colors.transparent,
              title: GestureDetector(
                onTap: () => WorkspaceSwitcherSheet.show(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          currentWorkspace.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  currentWorkspace.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 18, color: AppColors.textSecondary),
                            ],
                          ),
                          Text(
                            currentWorkspace.role.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  AppColors.textSecondary.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: NotificationBellButton(),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.primary),
                  tooltip: 'Switch Workspace',
                  onPressed: () => WorkspaceSwitcherSheet.show(context),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: AppColors.primary),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkspaceSettingsScreen(
                          workspaceId: currentWorkspace.id,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats row
                  _buildStatsRow(currentWorkspace),
                  const SizedBox(height: 20),

                  // Quick Action Chips
                  _buildQuickActions(context, currentWorkspace),
                  const SizedBox(height: 24),

                  // Projects list section
                  _buildProjectsSection(context, projectsAsync, currentWorkspace),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Workspace currentWorkspace) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people_outline_rounded,
            label: 'Members',
            value: '${currentWorkspace.memberCount}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.folder_outlined,
            label: 'Projects',
            value: '${currentWorkspace.projectCount}',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.shield_outlined,
            label: 'Role',
            value: currentWorkspace.role.displayName,
            color: AppColors.success,
            isSmallText: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isSmallText = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallText ? 13 : 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Workspace currentWorkspace) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (currentWorkspace.role.isAdminOrAbove)
            _buildQuickActionChip(
              icon: Icons.person_add_outlined,
              label: 'Invite Member',
              onTap: () =>
                  InviteMemberDialog.show(context, currentWorkspace.id),
            ),
          _buildQuickActionChip(
            icon: Icons.add_business_outlined,
            label: 'New Workspace',
            onTap: () => CreateWorkspaceDialog.show(context),
          ),
          _buildQuickActionChip(
            icon: Icons.link_rounded,
            label: 'Join with Token',
            onTap: () => AcceptInviteDialog.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsSection(
    BuildContext context,
    AsyncValue<List<Project>>? projectsAsync,
    Workspace currentWorkspace,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ACTIVE PROJECTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: AppColors.textSecondary,
              ),
            ),
            if (currentWorkspace.role.isManagerOrAbove)
              GestureDetector(
                onTap: () =>
                    CreateProjectDialog.show(context, currentWorkspace.id),
                child: const Text(
                  '+ New Project',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (projectsAsync == null)
          const SizedBox.shrink()
        else
          projectsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => Center(
              child: Text('Error loading projects: $err'),
            ),
            data: (projects) {
              if (projects.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.folder_open_outlined,
                          size: 40, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      const Text(
                        'No projects yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create your first project to start Kanban boards.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: projects.map((p) {
                  return ProjectCard(
                    project: p,
                    onTap: () {
                      context.push('/projects/${p.id}');
                    },
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyWorkspaceState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hub_outlined, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Select a Workspace',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create or switch to a workspace to access projects and Kanban boards.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          AppButton(
            text: 'Create Workspace',
            onPressed: () => CreateWorkspaceDialog.show(context),
          ),
        ],
      ),
    );
  }
}
