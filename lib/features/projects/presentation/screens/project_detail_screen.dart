import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
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
            content: Text('Moved to ${newStatus.displayName}'),
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
      appBar: AppBar(
        titleSpacing: 0,
        title: projectAsync.when(
          data: (project) => Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  project.key,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  project.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          loading: () => const Text('Loading project...'),
          error: (_, _) => const Text('Project'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.view_kanban_outlined, size: 20),
              text: 'Kanban Board',
            ),
            Tab(
              icon: Icon(Icons.format_list_bulleted, size: 20),
              text: 'Task List',
            ),
          ],
        ),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load tasks: $err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(projectTasksProvider(widget.projectId));
                  ref.invalidate(projectDetailProvider(widget.projectId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (tasks) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Kanban Board
              _buildKanbanBoard(tasks, projectAsync.valueOrNull),

              // Tab 2: Task List
              _buildTaskList(tasks, projectAsync.valueOrNull),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
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
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // KANBAN BOARD VIEW
  Widget _buildKanbanBoard(List<TaskModel> allTasks, Project? project) {
    const statuses = TaskStatus.values;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(projectTasksProvider(widget.projectId));
        ref.invalidate(projectDetailProvider(widget.projectId));
      },
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        children: statuses.map((status) {
          final columnTasks =
              allTasks.where((t) => t.status == status).toList();

          return Container(
            width: 290,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Column Header
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(status.icon, size: 18, color: status.color),
                          const SizedBox(width: 8),
                          Text(
                            status.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${columnTasks.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),

                // Tasks in this column
                Expanded(
                  child: columnTasks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 32,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No ${status.displayName} tasks',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(10),
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
                  padding: const EdgeInsets.all(8.0),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (project != null) {
                        CreateTaskDialog.show(
                          context,
                          projectId: project.id,
                          workspaceId: project.workspaceId,
                          initialStatus: status,
                        );
                      }
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Task'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
          color: AppColors.surface,
          child: Column(
            children: [
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedStatusFilter == null,
                      onSelected: (selected) {
                        setState(() => _selectedStatusFilter = null);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedStatusFilter == null
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...TaskStatus.values.map((status) {
                      final isSelected = _selectedStatusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(status.displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatusFilter =
                                  selected ? status : null;
                            });
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(projectTasksProvider(widget.projectId));
              ref.invalidate(projectDetailProvider(widget.projectId));
            },
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No tasks found matching filter',
                      style: TextStyle(color: AppColors.textSecondary),
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
}
