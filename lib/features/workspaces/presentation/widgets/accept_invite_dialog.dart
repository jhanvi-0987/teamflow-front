import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/invitation.dart';
import '../providers/workspace_providers.dart';

class AcceptInviteDialog extends ConsumerStatefulWidget {
  const AcceptInviteDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AcceptInviteDialog(),
    );
  }

  @override
  ConsumerState<AcceptInviteDialog> createState() => _AcceptInviteDialogState();
}

class _AcceptInviteDialogState extends ConsumerState<AcceptInviteDialog> {
  final _tokenController = TextEditingController();
  bool _isLoadingPreview = false;
  bool _isAccepting = false;
  Invitation? _preview;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _fetchPreview() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    setState(() => _isLoadingPreview = true);
    try {
      final repo = ref.read(workspacesRepositoryProvider);
      final preview = await repo.previewInvitation(token);
      if (mounted) {
        setState(() {
          _preview = preview;
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPreview = false);
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

  Future<void> _accept() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    setState(() => _isAccepting = true);
    final success = await ref
        .read(workspaceControllerProvider.notifier)
        .acceptInvitation(token);

    if (mounted) {
      setState(() => _isAccepting = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Joined workspace successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        final err = ref.read(workspaceControllerProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err ?? 'Failed to accept invitation'),
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
                    child: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join Workspace',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Enter your invitation token to gain access',
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

              // Token input
              AppTextField(
                label: 'Invitation Token',
                hint: 'Paste your invitation token here',
                controller: _tokenController,
                prefixIcon: const Icon(Icons.key_rounded, size: 20, color: AppColors.primary),
              ),
              const SizedBox(height: 16),

              if (_preview == null) ...[
                AppButton(
                  text: 'Verify Token',
                  isSecondary: true,
                  icon: Icons.search_rounded,
                  isLoading: _isLoadingPreview,
                  onPressed: _fetchPreview,
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            (_preview!.workspaceName ?? 'T').substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _preview!.workspaceName ?? 'TeamFlow Workspace',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Role: ${_preview!.role.displayName}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                        text: 'Accept & Join',
                        icon: Icons.login_rounded,
                        isLoading: _isAccepting,
                        onPressed: _accept,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
