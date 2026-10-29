import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/label_model.dart';
import '../../domain/models/task_model.dart';
import '../providers/task_providers.dart';

class LabelPickerSheet extends ConsumerStatefulWidget {
  final TaskModel task;
  final String workspaceId;

  const LabelPickerSheet({
    super.key,
    required this.task,
    required this.workspaceId,
  });

  static Future<void> show(
    BuildContext context, {
    required TaskModel task,
    required String workspaceId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LabelPickerSheet(task: task, workspaceId: workspaceId),
    );
  }

  @override
  ConsumerState<LabelPickerSheet> createState() => _LabelPickerSheetState();
}

class _LabelPickerSheetState extends ConsumerState<LabelPickerSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _isCreating = false;
  String _selectedColor = '#790D16';

  static const List<String> _palette = [
    '#790D16', // TeamFlow Burgundy
    '#2563EB', // Royal Blue
    '#059669', // Emerald Green
    '#D97706', // Warm Amber
    '#7C3AED', // Violet Purple
    '#DC2626', // Ruby Red
    '#0D9488', // Teal
    '#4B5563', // Slate Charcoal
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Future<void> _toggleLabel(LabelModel label, bool isAttached) async {
    final repo = ref.read(tasksRepositoryProvider);
    try {
      if (isAttached) {
        await repo.removeLabelFromTask(widget.task.id, label.id);
      } else {
        await repo.addLabelToTask(widget.task.id, label.id);
      }
      ref.invalidate(taskDetailProvider(widget.task.id));
      ref.invalidate(projectTasksProvider(widget.task.projectId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update label: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _createAndAttach() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      final repo = ref.read(tasksRepositoryProvider);
      final created = await repo.createWorkspaceLabel(
        widget.workspaceId,
        name,
        _selectedColor,
      );
      await repo.addLabelToTask(widget.task.id, created.id);

      ref.invalidate(workspaceLabelsProvider(widget.workspaceId));
      ref.invalidate(taskDetailProvider(widget.task.id));
      ref.invalidate(projectTasksProvider(widget.task.projectId));

      _nameController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created label "$name"'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create label: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelsAsync = ref.watch(workspaceLabelsProvider(widget.workspaceId));
    final activeLabelIds = widget.task.labels.map((l) => l.id).toSet();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.label_outline_rounded,
                      color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Task Labels & Tags',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Available labels list
          labelsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Failed to load labels: $err',
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
            data: (workspaceLabels) {
              if (workspaceLabels.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No labels yet in this workspace. Create one below!',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: workspaceLabels.map((lbl) {
                  final isAttached = activeLabelIds.contains(lbl.id);
                  final pillColor = lbl.color;

                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _toggleLabel(lbl, isAttached),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isAttached
                            ? pillColor
                            : pillColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: pillColor,
                          width: isAttached ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAttached
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 14,
                            color: isAttached ? Colors.white : pillColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            lbl.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isAttached ? Colors.white : pillColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Create New Label Section
          const Text(
            'CREATE NEW LABEL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),

          // Color palette picker row
          Row(
            children: _palette.map((colorHex) {
              final isSelected = _selectedColor == colorHex;
              final col = _parseHex(colorHex);

              return GestureDetector(
                onTap: () => setState(() => _selectedColor = colorHex),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: col,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: col.withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Input field and create button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Bug, Frontend, Security...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isCreating ? null : _createAndAttach,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Create',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

