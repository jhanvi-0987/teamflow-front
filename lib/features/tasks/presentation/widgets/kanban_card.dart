import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/task_model.dart';

class KanbanCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final ValueChanged<TaskStatus>? onStatusChanged;

  const KanbanCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onStatusChanged,
  });

  TaskStatus? get _nextStatus {
    switch (task.status) {
      case TaskStatus.todo:
        return TaskStatus.inProgress;
      case TaskStatus.inProgress:
        return TaskStatus.inReview;
      case TaskStatus.inReview:
        return TaskStatus.done;
      case TaskStatus.done:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color accent strip based on status
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: task.status.color,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top meta row: Priority and Version badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Priority Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: task.priority.color
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  task.priority.icon,
                                  size: 12,
                                  color: task.priority.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.priority.displayName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: task.priority.color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Concurrency version badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'v${task.version}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Labels row
                      if (task.hasLabels) ...[
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: task.labels.map((lbl) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: lbl.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: lbl.color.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                lbl.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: lbl.color,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Title
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                      ),

                      // Description (if present)
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          task.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        ),
                      ],

                      // Mini subtasks progress bar
                      if (task.hasSubtasks) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: task.subtaskProgress,
                            minHeight: 3,
                            backgroundColor:
                                AppColors.border.withValues(alpha: 0.25),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              task.completedSubtasks == task.totalSubtasks
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Bottom row: Assignee, comment count, and quick-advance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left side: Assignee + Comments
                          Row(
                            children: [
                              // Assignee Avatar
                              if (task.assignee != null)
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      task.assignee!.name.isNotEmpty
                                          ? task.assignee!.name
                                              .substring(0, 1)
                                              .toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.border
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              const SizedBox(width: 8),

                              // Comments count
                              if (task.commentCount > 0) ...[
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 13,
                                  color: AppColors.textMuted
                                      .withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${task.commentCount}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],

                              // Subtasks checklist indicator
                              if (task.hasSubtasks) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  task.completedSubtasks == task.totalSubtasks
                                      ? Icons.task_alt_rounded
                                      : Icons.checklist_rounded,
                                  size: 13,
                                  color: task.completedSubtasks ==
                                          task.totalSubtasks
                                      ? AppColors.success
                                      : AppColors.textMuted
                                          .withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${task.completedSubtasks}/${task.totalSubtasks}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: task.completedSubtasks ==
                                            task.totalSubtasks
                                        ? AppColors.success
                                        : AppColors.textMuted
                                            .withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Right side: Quick status advance button
                          if (_nextStatus != null &&
                              onStatusChanged != null)
                            Material(
                              color: _nextStatus!.color
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () =>
                                    onStatusChanged!(_nextStatus!),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _nextStatus!.icon,
                                        size: 12,
                                        color: _nextStatus!.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _nextStatus!.displayName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _nextStatus!.color,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
