import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/subtask_model.dart';
import '../../domain/models/task_model.dart';
import '../providers/task_providers.dart';

class SubtaskChecklistWidget extends ConsumerStatefulWidget {
  final TaskModel task;

  const SubtaskChecklistWidget({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<SubtaskChecklistWidget> createState() =>
      _SubtaskChecklistWidgetState();
}

class _SubtaskChecklistWidgetState
    extends ConsumerState<SubtaskChecklistWidget> {
  final TextEditingController _newSubtaskController = TextEditingController();
  bool _isAdding = false;
  bool _showAddInput = false;

  @override
  void dispose() {
    _newSubtaskController.dispose();
    super.dispose();
  }

  Future<void> _toggleSubtask(SubtaskModel subtask) async {
    final repo = ref.read(tasksRepositoryProvider);
    try {
      await repo.updateSubtask(
        widget.task.id,
        subtask.id,
        isCompleted: !subtask.isCompleted,
      );
      ref.invalidate(taskDetailProvider(widget.task.id));
      ref.invalidate(projectTasksProvider(widget.task.projectId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update subtask: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteSubtask(SubtaskModel subtask) async {
    final repo = ref.read(tasksRepositoryProvider);
    try {
      await repo.deleteSubtask(widget.task.id, subtask.id);
      ref.invalidate(taskDetailProvider(widget.task.id));
      ref.invalidate(projectTasksProvider(widget.task.projectId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete subtask: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _addSubtask() async {
    final title = _newSubtaskController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isAdding = true);
    try {
      final repo = ref.read(tasksRepositoryProvider);
      await repo.createSubtask(widget.task.id, title);
      _newSubtaskController.clear();
      setState(() => _showAddInput = false);

      ref.invalidate(taskDetailProvider(widget.task.id));
      ref.invalidate(projectTasksProvider(widget.task.projectId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add subtask: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtasks = widget.task.subtasks;
    final total = widget.task.totalSubtasks;
    final completed = widget.task.completedSubtasks;
    final progress = widget.task.subtaskProgress;
    final isAllDone = total > 0 && completed == total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count badge and Add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isAllDone
                          ? AppColors.successLight
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isAllDone
                          ? Icons.task_alt_rounded
                          : Icons.checklist_rounded,
                      size: 16,
                      color: isAllDone ? AppColors.success : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Subtasks & Checklist',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (total > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAllDone
                            ? AppColors.successLight
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$completed/$total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isAllDone
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _showAddInput = !_showAddInput);
                },
                icon: Icon(
                  _showAddInput ? Icons.close : Icons.add_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  _showAddInput ? 'Cancel' : 'Add',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          // Progress Bar (if items exist)
          if (total > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.border.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAllDone ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // List of Subtasks
          if (subtasks.isEmpty && !_showAddInput) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No subtasks yet. Break this task into smaller steps!',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subtasks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final subtask = subtasks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // Checkbox
                      InkWell(
                        onTap: () => _toggleSubtask(subtask),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: subtask.isCompleted
                                ? AppColors.success
                                : Colors.transparent,
                            border: Border.all(
                              color: subtask.isCompleted
                                  ? AppColors.success
                                  : AppColors.border,
                              width: 1.8,
                            ),
                          ),
                          child: subtask.isCompleted
                              ? const Icon(Icons.check,
                                  size: 12, color: Colors.white)
                              : const SizedBox(width: 12, height: 12),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Title
                      Expanded(
                        child: Text(
                          subtask.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: subtask.isCompleted
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            decoration: subtask.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),

                      // Delete action
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete subtask',
                        onPressed: () => _deleteSubtask(subtask),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          // Quick Add Input Box
          if (_showAddInput) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSubtaskController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Add a subtask...',
                      hintStyle: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.5)),
                      ),
                    ),
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isAdding ? null : _addSubtask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isAdding
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

