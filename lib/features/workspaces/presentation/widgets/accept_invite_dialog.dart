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
          const SnackBar(
            content: Text('Joined workspace successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final err = ref.read(workspaceControllerProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err ?? 'Failed to accept invitation'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      backgroundColor: AppColors.surface,
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
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.mail_outline, color: AppColors.accent),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Join with Invitation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Invitation Token',
              hint: 'Paste your invitation token here',
              controller: _tokenController,
            ),
            const SizedBox(height: 12),
            if (_preview == null)
              AppButton(
                text: 'Verify Token',
                isSecondary: true,
                isLoading: _isLoadingPreview,
                onPressed: _fetchPreview,
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _preview!.workspaceName ?? 'TeamFlow Workspace',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invited as ${_preview!.role.displayName}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
    );
  }
}
