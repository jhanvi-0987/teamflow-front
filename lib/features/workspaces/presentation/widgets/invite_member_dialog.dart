import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/workspace.dart';
import '../providers/workspace_providers.dart';

class InviteMemberDialog extends ConsumerStatefulWidget {
  final String workspaceId;

  const InviteMemberDialog({super.key, required this.workspaceId});

  static Future<void> show(BuildContext context, String workspaceId) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => InviteMemberDialog(workspaceId: workspaceId),
    );
  }

  @override
  ConsumerState<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  WorkspaceRole _selectedRole = WorkspaceRole.member;
  bool _isLoading = false;
  String? _generatedToken;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(workspacesRepositoryProvider);
      final invitation = await repo.inviteMember(
        widget.workspaceId,
        _emailController.text.trim(),
        _selectedRole,
      );

      ref.invalidate(workspaceInvitationsProvider(widget.workspaceId));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _generatedToken = invitation.inviteToken;
        });
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
    if (_generatedToken != null) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invitation Ready!',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Share the token with your team member',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                const SizedBox(height: 18),
                Text(
                  'Invitation token generated for ${_emailController.text.trim()}:',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                  ),
                  child: SelectableText(
                    _generatedToken!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Copy Token',
                        icon: Icons.copy_rounded,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _generatedToken!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text('Token copied to clipboard!'),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: 'Done',
                        isSecondary: true,
                        onPressed: () => Navigator.of(context).pop(),
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
                      child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invite Member',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Invite a colleague to collaborate in this workspace',
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

                // Email Field
                AppTextField(
                  label: 'Email Address',
                  hint: 'colleague@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Role Selection
                const Text(
                  'Workspace Role',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<WorkspaceRole>(
                      value: _selectedRole,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      items: const [
                        DropdownMenuItem(
                          value: WorkspaceRole.member,
                          child: Text(
                            'Member (view & complete assigned tasks)',
                            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ),
                        DropdownMenuItem(
                          value: WorkspaceRole.manager,
                          child: Text(
                            'Manager (create projects & assign tasks)',
                            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ),
                        DropdownMenuItem(
                          value: WorkspaceRole.admin,
                          child: Text(
                            'Admin (manage members & settings)',
                            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                      onChanged: (role) {
                        if (role != null) setState(() => _selectedRole = role);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
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
                        text: 'Send Invite',
                        icon: Icons.send_rounded,
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
