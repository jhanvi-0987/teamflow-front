import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/project_providers.dart';
import '../../../workspaces/presentation/providers/workspace_providers.dart';

class CreateProjectDialog extends ConsumerStatefulWidget {
  final String workspaceId;

  const CreateProjectDialog({super.key, required this.workspaceId});

  static Future<void> show(BuildContext context, String workspaceId) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CreateProjectDialog(workspaceId: workspaceId),
    );
  }

  @override
  ConsumerState<CreateProjectDialog> createState() =>
      _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _keyController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNameChanged(String val) {
    if (_keyController.text.isEmpty || _keyController.text.length <= 4) {
      final words = val.trim().split(RegExp(r'\s+'));
      String generated = '';
      if (words.length >= 2) {
        generated = words.take(4).map((w) => w.isNotEmpty ? w[0] : '').join();
      } else if (val.length >= 3) {
        generated = val.substring(0, val.length.clamp(3, 4));
      }
      _keyController.text = generated.toUpperCase();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(projectsRepositoryProvider);
      await repo.createProject(
        workspaceId: widget.workspaceId,
        name: _nameController.text.trim(),
        key: _keyController.text.trim().toUpperCase(),
        description: _descriptionController.text.trim(),
      );

      // Refresh project list and workspace stats
      ref.invalidate(workspaceProjectsProvider(widget.workspaceId));
      ref.read(workspaceControllerProvider.notifier).loadWorkspaces();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Project "${_nameController.text.trim()}" created!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                      child: const Icon(Icons.folder_open_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Project',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Organize and track tasks for your team',
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

                // Name Field
                AppTextField(
                  label: 'Project Name',
                  hint: 'e.g. Mobile App Redesign',
                  controller: _nameController,
                  onChanged: _onNameChanged,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Project name is required';
                    }
                    if (val.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Key Field
                AppTextField(
                  label: 'Project Key',
                  hint: 'e.g. MOB (uppercase letters/numbers)',
                  controller: _keyController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Key is required';
                    }
                    final trimmed = val.trim().toUpperCase();
                    if (!RegExp(r'^[A-Z0-9]{2,10}$').hasMatch(trimmed)) {
                      return '2-10 uppercase alphanumeric characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description Field
                AppTextField(
                  label: 'Description (Optional)',
                  hint: 'Brief overview or goal of this project',
                  controller: _descriptionController,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

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
                        text: 'Create Project',
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
