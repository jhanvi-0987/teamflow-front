import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/task_model.dart';
import '../../../workspaces/presentation/providers/workspace_providers.dart';

/// Modal bottom sheet allowing searching users across the platform by email or name,
/// including users without any group/workspace, and assigning them to tasks.
class AssigneePickerSheet extends ConsumerStatefulWidget {
  final String workspaceId;
  final String? currentAssigneeId;
  final ValueChanged<UserSummary?> onSelected;

  const AssigneePickerSheet({
    super.key,
    required this.workspaceId,
    required this.currentAssigneeId,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String workspaceId,
    required String? currentAssigneeId,
    required ValueChanged<UserSummary?> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssigneePickerSheet(
        workspaceId: workspaceId,
        currentAssigneeId: currentAssigneeId,
        onSelected: onSelected,
      ),
    );
  }

  @override
  ConsumerState<AssigneePickerSheet> createState() =>
      _AssigneePickerSheetState();
}

class _AssigneePickerSheetState extends ConsumerState<AssigneePickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  List<UserSummary> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final clean = query.trim();
      setState(() {
        _searchQuery = clean;
      });

      if (clean.isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        return;
      }

      setState(() => _isSearching = true);
      try {
        final repo = ref.read(workspacesRepositoryProvider);
        final members = await repo.getMembers(widget.workspaceId, query: clean);
        final results = members
            .map((m) => UserSummary(id: m.userId, name: m.name, email: m.email))
            .toList();
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(workspaceMembersProvider(widget.workspaceId));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_search_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign Task',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Search teammates or invite by email',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search text field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by email or name...',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceVariant.withValues(alpha: 0.45),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(height: 14),

              // User list
              Expanded(
                child: membersAsync.when(
                  data: (members) {
                    final memberMap = {for (var m in members) m.userId: m};

                    // If searching: display search results
                    if (_searchQuery.isNotEmpty) {
                      if (_isSearching) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        );
                      }

                      if (_searchResults.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_off_rounded,
                                    size: 36,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No workspace members found matching "$_searchQuery"',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Only members of this workspace can be assigned tasks. Send an invitation from Workspace Settings to add collaborators.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _searchResults.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildUnassignedTile();
                          }
                          final user = _searchResults[index - 1];
                          final memberInfo = memberMap[user.id];
                          final isSelected = widget.currentAssigneeId == user.id;

                          return _buildUserTile(
                            user: user,
                            isSelected: isSelected,
                            roleBadge: memberInfo != null
                                ? memberInfo.role.displayName.toUpperCase()
                                : 'MEMBER',
                            isExternal: false,
                          );
                        },
                      );
                    }

                    // Default view: Show Unassigned + Workspace Members
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      children: [
                        _buildUnassignedTile(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.group_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'WORKSPACE MEMBERS (${members.length})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...members.map((m) {
                          final isSelected = widget.currentAssigneeId == m.userId;
                          final user = UserSummary(
                            id: m.userId,
                            name: m.name,
                            email: m.email,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildUserTile(
                              user: user,
                              isSelected: isSelected,
                              roleBadge: m.role.displayName.toUpperCase(),
                              isExternal: false,
                            ),
                          );
                        }),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 16,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tip: Filter members by name or email. To assign someone new, send an invitation in Workspace Settings.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load members: $e',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnassignedTile() {
    final isSelected = widget.currentAssigneeId == null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        widget.onSelected(null);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceVariant.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_off_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unassigned',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Leave task without an assignee',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile({
    required UserSummary user,
    required bool isSelected,
    required String roleBadge,
    required bool isExternal,
  }) {
    final initial = user.name.isNotEmpty
        ? user.name.substring(0, 1).toUpperCase()
        : user.email.isNotEmpty
            ? user.email.substring(0, 1).toUpperCase()
            : '?';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        widget.onSelected(user);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: isExternal ? null : AppColors.primaryGradient,
                color: isExternal ? AppColors.accent.withValues(alpha: 0.2) : null,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: isExternal ? AppColors.accent : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name.isNotEmpty ? user.name : user.email,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isExternal
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isExternal
                                ? AppColors.accent.withValues(alpha: 0.4)
                                : AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          roleBadge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: isExternal ? AppColors.accent : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isExternal)
                    Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: Text(
                        'Will be invited to workspace automatically',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
