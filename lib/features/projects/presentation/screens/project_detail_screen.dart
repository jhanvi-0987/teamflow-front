import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../domain/models/project.dart';
import '../../../tasks/domain/models/task_model.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/presentation/widgets/kanban_card.dart';
import '../../../tasks/presentation/widgets/create_task_dialog.dart';
import '../providers/project_providers.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  TaskStatus? _selectedStatusFilter;
  List<StreamSubscription> _socketSubscriptions = [];
  SocketService? _socketService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupRealtime();
  }

  void _setupRealtime() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final socketService = ref.read(socketServiceProvider);
      _socketService = socketService;
      socketService.connect();
      socketService.joinProject(widget.projectId);

      _socketSubscriptions = [
        socketService.onTaskCreated.listen((event) {
          if (event['projectId'] == widget.projectId && mounted) {
            ref.invalidate(projectTasksProvider(widget.projectId));
            ref.invalidate(projectDetailProvider(widget.projectId));
          }
        }),
        socketService.onTaskUpdated.listen((event) {
          if (event['projectId'] == widget.projectId && mounted) {
            ref.invalidate(projectTasksProvider(widget.projectId));
          }
        }),
        socketService.onTaskStatusChanged.listen((event) {
          if (event['projectId'] == widget.projectId && mounted) {
            ref.invalidate(projectTasksProvider(widget.projectId));
          }
        }),
        socketService.onTaskDeleted.listen((event) {
          if (event['projectId'] == widget.projectId && mounted) {
            ref.invalidate(projectTasksProvider(widget.projectId));
            ref.invalidate(projectDetailProvider(widget.projectId));
          }
        }),
      ];
    });
  }

  @override
  void dispose() {
    for (final sub in _socketSubscriptions) {
      sub.cancel();
    }
    _socketSubscriptions.clear();
    _socketService?.leaveProject(widget.projectId);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleStatusAdvance(TaskModel task, TaskStatus newStatus) async {
    try {
      final repo = ref.read(tasksRepositoryProvider);
      await repo.transitionStatus(
        task.id,
        newStatus,
        version: task.version,
      );

      // Refresh task lists
      ref.invalidate(projectTasksProvider(widget.projectId));
      ref.invalidate(projectDetailProvider(widget.projectId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(newStatus.icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('Moved to ${newStatus.displayName}'),
              ],
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      // Optimistic concurrency conflict or error
      ref.invalidate(projectTasksProvider(widget.projectId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('409')
                  ? 'Version Conflict: task modified elsewhere. Refreshing...'
                  : 'Failed to advance status: $e',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectDetailProvider(widget.projectId));
    final tasksAsync = ref.watch(projectTasksProvider(widget.projectId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
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
          onPressed: () => context.pop(),
        ),
        title: projectAsync.when(
          data: (project) => Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  project.key,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  project.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          loading: () => const Text('Loading project...'),
          error: (_, _) => const Text('Project'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(3),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.view_kanban_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('Board'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.format_list_bulleted_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('List'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Live indicator
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded,
                      size: 40, color: AppColors.error),
                ),
                const SizedBox(height: 20),
                Text(
                  'Failed to load tasks',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$err',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(projectTasksProvider(widget.projectId));
                    ref.invalidate(projectDetailProvider(widget.projectId));
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (tasks) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildKanbanBoard(tasks, projectAsync.valueOrNull),
              _buildTaskList(tasks, projectAsync.valueOrNull),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.buttonShadow,
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            final project = projectAsync.valueOrNull;
            if (project != null) {
              CreateTaskDialog.show(
                context,
                projectId: project.id,
                workspaceId: project.workspaceId,
              );
            }
          },
          backgroundColor: AppColors.primary,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'New Task',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // KANBAN BOARD VIEW
  Widget _buildKanbanBoard(List<TaskModel> allTasks, Project? project) {
    const statuses = TaskStatus.values;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(projectTasksProvider(widget.projectId));
        ref.invalidate(projectDetailProvider(widget.projectId));
      },
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        children: statuses.map((status) {
          final columnTasks =
              allTasks.where((t) => t.status == status).toList();

          return Container(
            width: 300,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Column Header
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.04),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: status.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(status.icon,
                                size: 16, color: status.color),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            status.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          '${columnTasks.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tasks in this column
                Expanded(
                  child: columnTasks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 28,
                                  color: AppColors.textMuted
                                      .withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Empty',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted
                                        .withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          itemCount: columnTasks.length,
                          itemBuilder: (context, index) {
                            final task = columnTasks[index];
                            return KanbanCard(
                              task: task,
                              onTap: () {
                                context.push('/tasks/${task.id}');
                              },
                              onStatusChanged: (newStatus) =>
                                  _handleStatusAdvance(task, newStatus),
                            );
                          },
                        ),
                ),

                // Column quick add button
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Material(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (project != null) {
                          CreateTaskDialog.show(
                            context,
                            projectId: project.id,
                            workspaceId: project.workspaceId,
                            initialStatus: status,
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Add Task',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
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
          );
        }).toList(),
      ),
    );
  }

  // TASK LIST VIEW
  Widget _buildTaskList(List<TaskModel> allTasks, Project? project) {
    // Filter by search query
    final query = _searchController.text.toLowerCase().trim();
    var filtered = allTasks.where((t) {
      final matchesSearch = query.isEmpty ||
          t.title.toLowerCase().contains(query) ||
          (t.description != null &&
              t.description!.toLowerCase().contains(query));
      final matchesStatus =
          _selectedStatusFilter == null || t.status == _selectedStatusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      children: [
        // Search & Filter header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.3)),
            ),
          ),
          child: Column(
            children: [
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'All',
                      isSelected: _selectedStatusFilter == null,
                      onTap: () =>
                          setState(() => _selectedStatusFilter = null),
                    ),
                    const SizedBox(width: 8),
                    ...TaskStatus.values.map((status) {
                      final isSelected = _selectedStatusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildFilterChip(
                          label: status.displayName,
                          isSelected: isSelected,
                          color: status.color,
                          icon: status.icon,
                          onTap: () {
                            setState(() {
                              _selectedStatusFilter =
                                  isSelected ? null : status;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(projectTasksProvider(widget.projectId));
              ref.invalidate(projectDetailProvider(widget.projectId));
            },
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 40,
                            color: AppColors.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No tasks found',
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final task = filtered[index];
                      return KanbanCard(
                        task: task,
                        onTap: () {
                          context.push('/tasks/${task.id}');
                        },
                        onStatusChanged: (newStatus) =>
                            _handleStatusAdvance(task, newStatus),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.primary)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? AppColors.primary).withValues(alpha: 0.3)
                : AppColors.border.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
