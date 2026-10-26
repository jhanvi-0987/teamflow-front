import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/workspace_providers.dart';

class CreateWorkspaceDialog extends ConsumerStatefulWidget {
  const CreateWorkspaceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CreateWorkspaceDialog(),
    );
  }

  @override
  ConsumerState<CreateWorkspaceDialog> createState() =>
      _CreateWorkspaceDialogState();
}

class _CreateWorkspaceDialogState extends ConsumerState<CreateWorkspaceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  void _onNameChanged(String val) {
    if (_slugController.text.isEmpty ||
        _slugController.text == _slugify(_nameController.text)) {
      _slugController.text = _slugify(val);
    }
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final success = await ref
        .read(workspaceControllerProvider.notifier)
        .createWorkspace(
          name: _nameController.text.trim(),
          slug: _slugController.text.trim().isEmpty
              ? null
              : _slugController.text.trim(),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Workspace "${_nameController.text.trim()}" created!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        final error = ref.read(workspaceControllerProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to create workspace'),
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
                      child: const Icon(Icons.business_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Workspace',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'A dedicated hub for your team and projects',
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

                // Workspace Name Field
                AppTextField(
                  label: 'Workspace Name',
                  hint: 'e.g. Acme Engineering',
                  controller: _nameController,
                  onChanged: _onNameChanged,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Workspace name is required';
                    }
                    if (val.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Slug Field
                AppTextField(
                  label: 'Workspace Slug (Optional)',
                  hint: 'e.g. acme-engineering',
                  controller: _slugController,
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      final regex = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
                      if (!regex.hasMatch(val.trim())) {
                        return 'Lowercase alphanumeric and single hyphens only';
                      }
                    }
                    return null;
                  },
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
                        text: 'Create',
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
