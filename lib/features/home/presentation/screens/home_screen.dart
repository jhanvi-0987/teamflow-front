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
import 'package:go_router/go_router.dart';
import '../../../workspaces/presentation/screens/workspace_settings_screen.dart';
import '../../../workspaces/domain/models/workspace.dart';
import '../../../projects/domain/models/project.dart';
import '../../../projects/presentation/providers/project_providers.dart';
import '../../../projects/presentation/widgets/project_card.dart';
import '../../../projects/presentation/widgets/create_project_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workspaceControllerProvider.notifier).loadWorkspaces();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final workspaceState = ref.watch(workspaceControllerProvider);
    final currentWorkspace = workspaceState.currentWorkspace;
    final projectsAsync = currentWorkspace != null
        ? ref.watch(workspaceProjectsProvider(currentWorkspace.id))
        : null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.warmGradient,
        ),
        child: workspaceState.isLoading && workspaceState.workspaces.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await ref
                      .read(workspaceControllerProvider.notifier)
                      .loadWorkspaces();
                  if (currentWorkspace != null) {
                    ref.invalidate(
                        workspaceProjectsProvider(currentWorkspace.id));
                  }
                },
                child: CustomScrollView(
                  slivers: [
                    // Premium App Bar
                    SliverAppBar(
                      expandedHeight: 0,
                      floating: true,
                      backgroundColor: AppColors.background.withValues(alpha: 0.95),
                      surfaceTintColor: Colors.transparent,
                      title: GestureDetector(
                        onTap: () => WorkspaceSwitcherSheet.show(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Workspace avatar
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  currentWorkspace?.name
                                          .substring(0, 1)
                                          .toUpperCase() ??
                                      'T',
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
                                          currentWorkspace?.name ??
                                              'Select Workspace',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                            letterSpacing: -0.3,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.keyboard_arrow_down_rounded,
                                          size: 20, color: AppColors.textSecondary),
                                    ],
                                  ),
                                  if (currentWorkspace != null)
                                    Text(
                                      currentWorkspace.role.displayName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.7),
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
                        if (currentWorkspace != null)
                          _buildAppBarAction(
                            icon: Icons.settings_outlined,
                            tooltip: 'Workspace Settings',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => WorkspaceSettingsScreen(
                                    workspaceId: currentWorkspace.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        _buildAppBarAction(
                          icon: Icons.logout_rounded,
                          tooltip: 'Sign Out',
                          onTap: () {
                            ref.read(authControllerProvider.notifier).logout();
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),

                    // Content
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),

                              // Greeting section with time-based emoji
                              _buildGreetingSection(user?.name),
                              const SizedBox(height: 24),

                              if (currentWorkspace == null)
                                _buildEmptyWorkspaceState()
                              else ...[
                                // Workspace stats row
                                _buildStatsRow(currentWorkspace),
                                const SizedBox(height: 28),

                                // Quick Actions - horizontal scroll
                                _buildQuickActions(currentWorkspace),
                                const SizedBox(height: 24),

                                if (currentWorkspace.role.isAdminOrAbove) ...[
                                  _buildAdminDashboardCard(currentWorkspace),
                                  const SizedBox(height: 24),
                                ],

                                // Projects Section
                                _buildProjectsSection(
                                    projectsAsync, currentWorkspace),
                              ],

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: currentWorkspace != null && currentWorkspace.role.isManagerOrAbove
          ? Container(
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
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection(String? name) {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    if (hour < 12) {
      greeting = 'Good morning';
      emoji = '☀️';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
      emoji = '🌤️';
    } else {
      greeting = 'Good evening';
      emoji = '🌙';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting $emoji',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name ?? 'Teammate',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyWorkspaceState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.accent.withValues(alpha: 0.06),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rocket_launch_outlined,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Get Started',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a workspace or join a team to start collaborating on projects.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Create Workspace',
            icon: Icons.add_rounded,
            onPressed: () => CreateWorkspaceDialog.show(context),
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Join with Token',
            isSecondary: true,
            icon: Icons.link_rounded,
            onPressed: () => AcceptInviteDialog.show(context),
          ),
        ],
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
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.folder_outlined,
            label: 'Projects',
            value: '${currentWorkspace.projectCount}',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallText ? 13 : 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Workspace currentWorkspace) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (currentWorkspace.role.isAdminOrAbove)
            _buildQuickActionChip(
              icon: Icons.person_add_outlined,
              label: 'Invite',
              onTap: () =>
                  InviteMemberDialog.show(context, currentWorkspace.id),
            ),
          _buildQuickActionChip(
            icon: Icons.swap_horiz_rounded,
            label: 'Switch',
            onTap: () => WorkspaceSwitcherSheet.show(context),
          ),
          _buildQuickActionChip(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => WorkspaceSettingsScreen(
                    workspaceId: currentWorkspace.id,
                  ),
                ),
              );
            },
          ),
          _buildQuickActionChip(
            icon: Icons.add_rounded,
            label: 'Workspace',
            onTap: () => CreateWorkspaceDialog.show(context),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
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

  Widget _buildAdminDashboardCard(Workspace currentWorkspace) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            currentWorkspace.role.displayName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage team members, roles, invitations & governance',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WorkspaceSettingsScreen(
                          workspaceId: currentWorkspace.id,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_alt_outlined, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Members & Roles',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => InviteMemberDialog.show(context, currentWorkspace.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_outlined, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Invite Teammate',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection(
      AsyncValue<List<Project>>? projectsAsync, Workspace currentWorkspace) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.folder_outlined,
                    size: 20, color: AppColors.textPrimary),
                SizedBox(width: 8),
                Text(
                  'Projects',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            if (currentWorkspace.role.isManagerOrAbove)
              Material(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => CreateProjectDialog.show(
                  context,
                  currentWorkspace.id,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      const Text(
                        'New',
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
          ],
        ),
        const SizedBox(height: 14),

        if (projectsAsync != null)
          projectsAsync.when(
            loading: () => Container(
              padding: const EdgeInsets.all(40),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to load projects',
                      style: TextStyle(
                        color: AppColors.error.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(
                      workspaceProjectsProvider(currentWorkspace.id),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (projects) {
              if (projects.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.4)),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.folder_outlined,
                          color: AppColors.primary,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Projects Yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create your first project to start organizing tasks.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        text: 'Create Project',
                        icon: Icons.add_rounded,
                        onPressed: () => CreateProjectDialog.show(
                          context,
                          currentWorkspace.id,
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
}
