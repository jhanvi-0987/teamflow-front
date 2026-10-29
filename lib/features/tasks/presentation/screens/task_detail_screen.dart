import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../domain/models/task_model.dart';
import '../../domain/models/comment_model.dart';
import '../providers/task_providers.dart';
import '../../../workspaces/presentation/providers/workspace_providers.dart';
import '../widgets/assignee_picker_sheet.dart';
import '../widgets/label_picker_sheet.dart';
import '../widgets/subtask_checklist_widget.dart';


class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSendingComment = false;
  bool _isUpdatingTask = false;
  List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final socketService = ref.read(socketServiceProvider);
      socketService.connect();

      _subscriptions = [
        socketService.onCommentCreated.listen((event) {
          if (event['taskId'] == widget.taskId && mounted) {
            ref.invalidate(taskCommentsProvider(widget.taskId));
            ref.invalidate(taskDetailProvider(widget.taskId));
          }
        }),
        socketService.onTaskUpdated.listen((event) {
          final taskData = event['task'];
          if (taskData != null && taskData['id'] == widget.taskId && mounted) {
            ref.invalidate(taskDetailProvider(widget.taskId));
          }
        }),
        socketService.onTaskStatusChanged.listen((event) {
          if (event['taskId'] == widget.taskId && mounted) {
            ref.invalidate(taskDetailProvider(widget.taskId));
          }
        }),
        socketService.onSubtaskCreated.listen((event) {
          if (event['taskId'] == widget.taskId && mounted) {
            ref.invalidate(taskDetailProvider(widget.taskId));
          }
        }),
        socketService.onSubtaskUpdated.listen((event) {
          if (event['taskId'] == widget.taskId && mounted) {
            ref.invalidate(taskDetailProvider(widget.taskId));
          }
        }),
        socketService.onSubtaskDeleted.listen((event) {
          if (event['taskId'] == widget.taskId && mounted) {
            ref.invalidate(taskDetailProvider(widget.taskId));
          }
        }),
        socketService.onTaskLabelAdded.listen((event) {
          if (event['taskId'] == widget.taskId && mounted) {
            ref.invalidate(taskDetailProvider(widget.taskId));
          }
        }),
        socketService.onTaskLabelRemoved.listen((event) {
          if (event['taskId'] == widget.taskId && mounted) {
            ref.invalidate(taskDetailProvider(widget.taskId));
          }
        }),
      ];
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(TaskModel task, TaskStatus newStatus) async {
    setState(() => _isUpdatingTask = true);
    try {
      final repo = ref.read(tasksRepositoryProvider);
      await repo.transitionStatus(
        task.id,
        newStatus,
        version: task.version,
      );

      ref.invalidate(taskDetailProvider(widget.taskId));
      ref.invalidate(projectTasksProvider(task.projectId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(newStatus.icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('Status updated to ${newStatus.displayName}'),
              ],
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      ref.invalidate(taskDetailProvider(widget.taskId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('409')
                  ? 'Version Conflict: This task was modified by someone else. Reloading...'
                  : 'Failed to update status: $e',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingTask = false);
    }
  }

  Future<void> _updatePriority(TaskModel task, TaskPriority newPriority) async {
    setState(() => _isUpdatingTask = true);
    try {
      final repo = ref.read(tasksRepositoryProvider);
      await repo.updateTask(
        task.id,
        priority: newPriority,
        version: task.version,
      );

      ref.invalidate(taskDetailProvider(widget.taskId));
      ref.invalidate(projectTasksProvider(task.projectId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Priority updated to ${newPriority.displayName}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      ref.invalidate(taskDetailProvider(widget.taskId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('409')
                  ? 'Version Conflict: Concurrency mismatch. Reloaded latest version.'
                  : 'Failed to update priority: $e',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingTask = false);
    }
  }

  Future<void> _updateAssignee(TaskModel task) async {
    final workspace = ref.read(currentWorkspaceProvider);
    if (workspace == null) return;

    await AssigneePickerSheet.show(
      context,
      workspaceId: workspace.id,
      currentAssigneeId: task.assignee?.id,
      onSelected: (UserSummary? selectedUser) async {
        setState(() => _isUpdatingTask = true);
        try {
          final repo = ref.read(tasksRepositoryProvider);
          await repo.updateTask(
            task.id,
            assigneeId: selectedUser?.id,
            version: task.version,
          );

          ref.invalidate(taskDetailProvider(widget.taskId));
          ref.invalidate(projectTasksProvider(task.projectId));
          ref.invalidate(workspaceMembersProvider(workspace.id));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  selectedUser != null
                      ? 'Task assigned to ${selectedUser.name.isNotEmpty ? selectedUser.name : selectedUser.email}'
                      : 'Task unassigned',
                ),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        } catch (e) {
          ref.invalidate(taskDetailProvider(widget.taskId));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e.toString().contains('409')
                      ? 'Version Conflict: Task modified by someone else. Reloaded latest version.'
                      : 'Failed to update assignee: $e',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isUpdatingTask = false);
        }
      },
    );
  }

  Future<void> _sendComment() async {

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingComment = true);
    try {
      final repo = ref.read(tasksRepositoryProvider);
      await repo.createComment(widget.taskId, text);

      _commentController.clear();
      ref.invalidate(taskCommentsProvider(widget.taskId));
      ref.invalidate(taskDetailProvider(widget.taskId));

      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(0, 42),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final repo = ref.read(tasksRepositoryProvider);
        await repo.deleteTask(task.id);
        ref.invalidate(projectTasksProvider(task.projectId));
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete task: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));
    final commentsAsync = ref.watch(taskCommentsProvider(widget.taskId));

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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (taskAsync.valueOrNull != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 18),
                ),
                tooltip: 'Delete Task',
                onPressed: () => _deleteTask(taskAsync.valueOrNull!),
              ),
            ),
        ],
      ),
      body: taskAsync.when(
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
                const Text(
                  'Error loading task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text('$err',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 13,
                    )),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(taskDetailProvider(widget.taskId)),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (task) {
          return Column(
            children: [
              if (_isUpdatingTask)
                LinearProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  minHeight: 3,
                ),

              // Main task scrollable content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Title with version badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Meta row: version + due date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_clock_outlined,
                                  size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                'v${task.version}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (task.dueAt != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.warningLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 13, color: AppColors.warning),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(task.dueAt!),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Status and Priority Controls
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownSection(
                            label: 'STATUS',
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<TaskStatus>(
                                isExpanded: true,
                                value: task.status,
                                items: TaskStatus.values.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: s.color
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Icon(s.icon,
                                              size: 14, color: s.color),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            s.displayName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: s.color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null &&
                                      newStatus != task.status) {
                                    _updateStatus(task, newStatus);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdownSection(
                            label: 'PRIORITY',
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<TaskPriority>(
                                isExpanded: true,
                                value: task.priority,
                                items: TaskPriority.values.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: p.color
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Icon(p.icon,
                                              size: 14, color: p.color),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            p.displayName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: p.color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newPriority) {
                                  if (newPriority != null &&
                                      newPriority != task.priority) {
                                    _updatePriority(task, newPriority);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Assignee & Reporter
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.4)),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _updateAssignee(task),
                              child: _buildPersonSection(
                                label: 'ASSIGNEE',
                                name: task.assignee?.name ?? 'Unassigned',
                                initial: task.assignee?.name.isNotEmpty == true
                                    ? task.assignee!.name
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : '?',
                                isEditable: true,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: AppColors.border.withValues(alpha: 0.4),
                          ),
                          Expanded(
                            child: _buildPersonSection(
                              label: 'REPORTER',
                              name: task.reporter?.name ?? 'Unknown',
                              initial: task.reporter?.name.isNotEmpty == true
                                  ? task.reporter!.name
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : 'R',
                              isEditable: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Description Section
                    _buildSectionHeader(
                      icon: Icons.description_outlined,
                      title: 'Description',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        task.description?.isNotEmpty == true
                            ? task.description!
                            : 'No description provided.',
                        style: TextStyle(
                          fontSize: 14,
                          color: task.description?.isNotEmpty == true
                              ? AppColors.textPrimary
                              : AppColors.textMuted.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Labels Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.label_outline_rounded,
                          title: 'Labels & Tags (${task.labels.length})',
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            final ws = ref.read(currentWorkspaceProvider);
                            if (ws != null) {
                              LabelPickerSheet.show(
                                context,
                                task: task,
                                workspaceId: ws.id,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add_rounded,
                                    size: 14, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Manage',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (task.labels.isEmpty)
                      InkWell(
                        onTap: () {
                          final ws = ref.read(currentWorkspaceProvider);
                          if (ws != null) {
                            LabelPickerSheet.show(
                              context,
                              task: task,
                              workspaceId: ws.id,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add_circle_outline_rounded,
                                  size: 16, color: AppColors.textMuted),
                              SizedBox(width: 8),
                              Text(
                                'Add labels (e.g. Bug, Frontend, High Impact)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...task.labels.map((lbl) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: lbl.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: lbl.color.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: lbl.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    lbl.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: lbl.color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          InkWell(
                            onTap: () {
                              final ws = ref.read(currentWorkspaceProvider);
                              if (ws != null) {
                                LabelPickerSheet.show(
                                  context,
                                  task: task,
                                  workspaceId: ws.id,
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded,
                                      size: 14, color: AppColors.textMuted),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),

                    // Subtasks & Checklist Section
                    SubtaskChecklistWidget(task: task),
                    const SizedBox(height: 26),

                    // Comments Header
                    _buildSectionHeader(
                      icon: Icons.chat_outlined,
                      title: 'Comments (${task.commentCount})',
                    ),
                    const SizedBox(height: 14),

                    // Comments List
                    commentsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Failed to load comments: $err',
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13),
                        ),
                      ),
                      data: (comments) {
                        if (comments.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(28),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      AppColors.border.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded,
                                    size: 32,
                                    color:
                                        AppColors.textMuted.withValues(alpha: 0.3)),
                                const SizedBox(height: 10),
                                Text(
                                  'No comments yet',
                                  style: TextStyle(
                                    color: AppColors.textMuted
                                        .withValues(alpha: 0.6),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Start the conversation below',
                                  style: TextStyle(
                                    color: AppColors.textMuted
                                        .withValues(alpha: 0.4),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return _buildCommentItem(comment);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Bottom Comment Input Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.3)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed:
                              _isSendingComment ? null : _sendComment,
                          icon: _isSendingComment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded,
                                  size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdownSection({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted.withValues(alpha: 0.6),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildPersonSection({
    required String label,
    required String name,
    required String initial,
    required bool isEditable,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
              if (isEditable) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.edit_outlined,
                  size: 11,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        comment.author.name.isNotEmpty
                            ? comment.author.name.substring(0, 1).toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    comment.author.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDateTime(comment.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, $hour:$minute $ampm';
  }
}
