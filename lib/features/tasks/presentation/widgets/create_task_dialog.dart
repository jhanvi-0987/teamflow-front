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
            content: Text(
              _selectedAssignee != null
                  ? 'Task created and assigned to ${_selectedAssignee!.name.isNotEmpty ? _selectedAssignee!.name : _selectedAssignee!.email}!'
                  : 'Task created successfully!',
            ),
            backgroundColor: AppColors.success,
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
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(workspaceMembersProvider(widget.workspaceId));

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      backgroundColor: AppColors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.add_task, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Create Task',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
              AppTextField(
                label: 'Description (Optional)',
                hint: 'What needs to be done?',
                controller: _descriptionController,
              ),
              const SizedBox(height: 16),

              // Priority Selector
              const Text(
                'Priority',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TaskPriority.values.map((p) {
                  final isSelected = _priority == p;
                  return ChoiceChip(
                    label: Text(p.displayName),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundColor: AppColors.surfaceVariant,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _priority = p);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Status Selector
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TaskStatus.values.map((s) {
                  final isSelected = _status == s;
                  return ChoiceChip(
                    label: Text(s.displayName),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundColor: AppColors.surfaceVariant,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _status = s);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Assignee Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assignee',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_selectedAssignee != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedAssignee = null),
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedAssignee != null
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: _selectedAssignee != null
                            ? AppColors.primary
                            : AppColors.border,
                        child: Icon(
                          _selectedAssignee != null
                              ? Icons.person
                              : Icons.person_search_outlined,
                          size: 16,
                          color: _selectedAssignee != null
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedAssignee != null
                                  ? (_selectedAssignee!.name.isNotEmpty
                                      ? _selectedAssignee!.name
                                      : _selectedAssignee!.email)
                                  : 'Unassigned (Tap to search by email)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: _selectedAssignee != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: _selectedAssignee != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_selectedAssignee != null)
                              Text(
                                _selectedAssignee!.email,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

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
    );
  }
}
