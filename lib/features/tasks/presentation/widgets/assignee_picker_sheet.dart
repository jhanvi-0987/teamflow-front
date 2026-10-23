import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/task_model.dart';
import '../providers/task_providers.dart';
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
        final repo = ref.read(tasksRepositoryProvider);
        final results = await repo.searchUsers(clean);
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
        return Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_search_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign Task',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Search any user by email to assign and auto-enroll',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search text field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Search by email or name...',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),

            // User list
            Expanded(
              child: membersAsync.when(
                data: (members) {
                  final memberMap = {for (var m in members) m.userId: m};

                  // If searching: display search results
                  if (_searchQuery.isNotEmpty) {
                    if (_isSearching) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (_searchResults.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.person_off_outlined,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No users found matching "$_searchQuery"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Make sure the email is spelled correctly or that the user has created an account.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _searchResults.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildUnassignedTile();
                        }
                        final user = _searchResults[index - 1];
                        final memberInfo = memberMap[user.id];
                        final isAlreadyMember = memberInfo != null;
                        final isSelected = widget.currentAssigneeId == user.id;

                        return _buildUserTile(
                          user: user,
                          isSelected: isSelected,
                          roleBadge: isAlreadyMember
                              ? memberInfo.role.displayName.toUpperCase()
                              : 'NEW MEMBER (AUTO-ADD)',
                          isExternal: !isAlreadyMember,
                        );
                      },
                    );
                  }

                  // Default view: Show Unassigned + Workspace Members
                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildUnassignedTile(),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 20, 6),
                        child: Text(
                          'WORKSPACE MEMBERS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      ...members.map((m) {
                        final isSelected = widget.currentAssigneeId == m.userId;
                        final user = UserSummary(
                          id: m.userId,
                          name: m.name,
                          email: m.email,
                        );
                        return _buildUserTile(
                          user: user,
                          isSelected: isSelected,
                          roleBadge: m.role.displayName.toUpperCase(),
                          isExternal: false,
                        );
                      }),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tip: Type an email in the search bar above to assign someone who has not joined this workspace yet.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
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
        );
      },
    );
  }

  Widget _buildUnassignedTile() {
    final isSelected = widget.currentAssigneeId == null;

    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.surfaceVariant,
        child: const Icon(
          Icons.person_off_outlined,
          color: AppColors.textSecondary,
          size: 18,
        ),
      ),
      title: const Text(
        'Unassigned',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: const Text(
        'Clear task assignee',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
          : null,
      onTap: () {
        widget.onSelected(null);
        Navigator.of(context).pop();
      },
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isExternal
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.primary,
        child: Text(
          initial,
          style: TextStyle(
            color: isExternal ? AppColors.primary : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.name.isNotEmpty ? user.name : user.email,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isExternal
                  ? AppColors.accent.withValues(alpha: 0.18)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isExternal
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
            ),
            child: Text(
              roleBadge,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                color: isExternal ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (isExternal)
            const Padding(
              padding: EdgeInsets.only(top: 2.0),
              child: Text(
                'Will be automatically added to workspace upon assignment',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
          : null,
      onTap: () {
        widget.onSelected(user);
        Navigator.of(context).pop();
      },
    );
  }
}
