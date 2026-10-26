import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/task_model.dart';
import '../providers/task_providers.dart';
import '../../../workspaces/presentation/providers/workspace_providers.dart';
import 'assignee_picker_sheet.dart';

class CreateTaskDialog extends ConsumerStatefulWidget {
  final String projectId;
  final String workspaceId;
  final TaskStatus initialStatus;

  const CreateTaskDialog({
    super.key,
    required this.projectId,
    required this.workspaceId,
    this.initialStatus = TaskStatus.todo,
  });

  static Future<void> show(
    BuildContext context, {
    required String projectId,
    required String workspaceId,
    TaskStatus initialStatus = TaskStatus.todo,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CreateTaskDialog(
        projectId: projectId,
        workspaceId: workspaceId,
        initialStatus: initialStatus,
      ),
    );
  }

  @override
  ConsumerState<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late TaskStatus _status;
  TaskPriority _priority = TaskPriority.medium;
  UserSummary? _selectedAssignee;
  DateTime? _dueAt;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now.add(const Duration(days: 2)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dueAt = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(tasksRepositoryProvider);
      await repo.createTask(
        projectId: widget.projectId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _status,
        priority: _priority,
        assigneeId: _selectedAssignee?.id,
        dueAt: _dueAt,
      );

      // Invalidate tasks cache and workspace members (in case external user was auto-added)
      ref.invalidate(projectTasksProvider(widget.projectId));
      ref.invalidate(workspaceMembersProvider(widget.workspaceId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedAssignee != null
                        ? 'Task created & assigned to ${_selectedAssignee!.name.isNotEmpty ? _selectedAssignee!.name : _selectedAssignee!.email}!'
                        : 'Task created successfully!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.6), width: 1.2),
      ),
      backgroundColor: AppColors.surface,
      elevation: 16,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Task',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Add details and assign to a team member',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Title Input
                AppTextField(
                  label: 'Task Title',
                  hint: 'e.g. Design app bar navigation',
                  controller: _titleController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description Input
                AppTextField(
                  label: 'Description (Optional)',
                  hint: 'What needs to be done? Add acceptance criteria...',
                  controller: _descriptionController,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Priority Selection
                const Text(
                  'Priority',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TaskPriority.values.map((p) {
                    final isSelected = _priority == p;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? p.color.withValues(alpha: 0.14)
                              : AppColors.surfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? p.color : AppColors.border.withValues(alpha: 0.5),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(p.icon, size: 14, color: isSelected ? p.color : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              p.displayName,
                              style: TextStyle(
                                color: isSelected ? p.color : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Status Selection
                const Text(
                  'Initial Status',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TaskStatus.values.map((s) {
                    final isSelected = _status == s;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _status = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? s.color.withValues(alpha: 0.14)
                              : AppColors.surfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? s.color : AppColors.border.withValues(alpha: 0.5),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(s.icon, size: 14, color: isSelected ? s.color : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              s.displayName,
                              style: TextStyle(
                                color: isSelected ? s.color : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Due Date & Assignee Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Due Date Picker Button
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Due Date',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (_dueAt != null)
                                GestureDetector(
                                  onTap: () => setState(() => _dueAt = null),
                                  child: const Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _selectDueDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _dueAt != null ? AppColors.primary : AppColors.border.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: _dueAt != null ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _dueAt != null
                                          ? '${_dueAt!.day}/${_dueAt!.month}/${_dueAt!.year}'
                                          : 'Select date',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: _dueAt != null ? FontWeight.w600 : FontWeight.normal,
                                        color: _dueAt != null ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Assignee Selector Tile
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Assignee',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (_selectedAssignee != null)
                                GestureDetector(
                                  onTap: () => setState(() => _selectedAssignee = null),
                                  child: const Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => AssigneePickerSheet.show(
                              context,
                              workspaceId: widget.workspaceId,
                              currentAssigneeId: _selectedAssignee?.id,
                              onSelected: (user) => setState(() => _selectedAssignee = user),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedAssignee != null
                                      ? AppColors.primary
                                      : AppColors.border.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      gradient: _selectedAssignee != null
                                          ? AppColors.primaryGradient
                                          : null,
                                      color: _selectedAssignee == null
                                          ? AppColors.border.withValues(alpha: 0.4)
                                          : null,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: _selectedAssignee != null
                                          ? Text(
                                              (_selectedAssignee!.name.isNotEmpty
                                                      ? _selectedAssignee!.name
                                                      : _selectedAssignee!.email)
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.person_add_alt_1_rounded,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedAssignee != null
                                          ? (_selectedAssignee!.name.isNotEmpty
                                              ? _selectedAssignee!.name
                                              : _selectedAssignee!.email.split('@').first)
                                          : 'Assign to...',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: _selectedAssignee != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: _selectedAssignee != null
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Cancel',
                        isSecondary: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: 'Create Task',
                        icon: Icons.check_rounded,
                        isLoading: _isLoading,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
