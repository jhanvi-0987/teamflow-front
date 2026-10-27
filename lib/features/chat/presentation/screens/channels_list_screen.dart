import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../workspaces/presentation/providers/workspace_providers.dart';
import '../../../workspaces/presentation/widgets/workspace_switcher_sheet.dart';
import '../../domain/models/channel_model.dart';
import '../providers/chat_providers.dart';
import 'channel_chat_screen.dart';

enum _ChatFilter { all, channels, directMessages }

class ChannelsListScreen extends ConsumerStatefulWidget {
  const ChannelsListScreen({super.key});

  @override
  ConsumerState<ChannelsListScreen> createState() => _ChannelsListScreenState();
}

class _ChannelsListScreenState extends ConsumerState<ChannelsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  _ChatFilter _activeFilter = _ChatFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateChannelDialog(BuildContext context, String workspaceId) {
    final nameController = TextEditingController();
    final topicController = TextEditingController();
    ChannelType selectedType = ChannelType.public;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tag_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Create Channel',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Channel Name',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.tag, size: 18, color: AppColors.primary),
                    hintText: 'e.g. mobile-team, design, announcements',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Topic (Optional)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: topicController,
                  decoration: InputDecoration(
                    hintText: 'What is this channel for?',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Channel Type:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      DropdownButton<ChannelType>(
                        value: selectedType,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                            value: ChannelType.public,
                            child: Row(
                              children: [
                                Icon(Icons.public_rounded, size: 16, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text('Public (#)', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: ChannelType.private,
                            child: Row(
                              children: [
                                Icon(Icons.lock_rounded, size: 16, color: Color(0xFFD97706)),
                                SizedBox(width: 6),
                                Text('Private (🔒)', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => selectedType = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                final name = nameController.text.trim().replaceAll(' ', '-').toLowerCase();
                if (name.isEmpty) return;

                Navigator.pop(ctx);
                try {
                  final repo = ref.read(chatRepositoryProvider);
                  final channel = await repo.createChannel(
                    workspaceId,
                    name: name,
                    topic: topicController.text.trim(),
                    type: selectedType,
                  );
                  ref.invalidate(workspaceChannelsProvider(workspaceId));
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChannelChatScreen(channel: channel),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Create Channel', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showStartDMDialog(String workspaceId, String currentUserId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        final membersAsync = ref.watch(workspaceMembersProvider(workspaceId));

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direct Message',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Pick a teammate to start a private conversation',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: membersAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (members) {
                    final otherMembers =
                        members.where((m) => m.userId != currentUserId).toList();

                    if (otherMembers.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline_rounded,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              const Text(
                                'No other members in this workspace yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Invite your team members via the Workspace tab.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: otherMembers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final m = otherMembers[i];
                        return Material(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              Navigator.pop(ctx);
                              try {
                                final repo = ref.read(chatRepositoryProvider);
                                final dm =
                                    await repo.getOrCreateDM(workspaceId, m.userId);
                                ref.invalidate(workspaceChannelsProvider(workspaceId));
                                if (context.mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChannelChatScreen(channel: dm),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error starting DM: $e')),
                                  );
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: const Color(0xFFE0E7FF),
                                        child: Text(
                                          m.name.isNotEmpty
                                              ? m.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Color(0xFF4338CA),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 11,
                                          height: 11,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF22C55E),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.5,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          m.email,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.send_rounded,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceControllerProvider).currentWorkspace;
    final currentUser = ref.watch(authControllerProvider).user;

    if (workspace == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business_outlined, size: 52, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'No Workspace Selected',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please select or create a workspace to view chats.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => WorkspaceSwitcherSheet.show(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Switch Workspace', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final channelsAsync = ref.watch(workspaceChannelsProvider(workspace.id));
    final userName = currentUser?.name.split(' ').first ?? 'Team Member';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Modern Header & App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 8,
                  16,
                  8,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFAF6E4), AppColors.background],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar Row: Workspace Chip + Action Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Workspace Switcher Pill
                        GestureDetector(
                          onTap: () => WorkspaceSwitcherSheet.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    workspace.name.isNotEmpty
                                        ? workspace.name[0].toUpperCase()
                                        : 'W',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 130),
                                  child: Text(
                                    workspace.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Action Icons
                        Row(
                          children: [
                            _HeaderIconButton(
                              icon: Icons.chat_bubble_outline_rounded,
                              tooltip: 'New DM',
                              onTap: () => _showStartDMDialog(workspace.id, currentUser?.id ?? ''),
                            ),
                            const SizedBox(width: 8),
                            _HeaderIconButton(
                              icon: Icons.add_rounded,
                              tooltip: 'New Channel',
                              onTap: () => _showCreateChannelDialog(context, workspace.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Greeting Headline
                    Text(
                      'Welcome back, $userName 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Team Chat & Live Channels',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search Bar & Filter Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                children: [
                  // Search TextField
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFEDE9E3)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search channels or teammates...',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textSecondary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips Row
                  Row(
                    children: [
                      _FilterChip(
                        label: 'All Chats',
                        isSelected: _activeFilter == _ChatFilter.all,
                        onTap: () => setState(() => _activeFilter = _ChatFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '# Channels',
                        isSelected: _activeFilter == _ChatFilter.channels,
                        onTap: () => setState(() => _activeFilter = _ChatFilter.channels),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '💬 Direct Messages',
                        isSelected: _activeFilter == _ChatFilter.directMessages,
                        onTap: () => setState(() => _activeFilter = _ChatFilter.directMessages),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Main Channels & DMs List
          channelsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 40),
                    const SizedBox(height: 12),
                    Text('Failed to load chat channels\n$err',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () =>
                          ref.invalidate(workspaceChannelsProvider(workspace.id)),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            data: (channels) {
              // Apply search filtering
              final filtered = channels.where((c) {
                if (_searchQuery.isEmpty) return true;
                final nameMatches = c.name.toLowerCase().contains(_searchQuery);
                final topicMatches = c.topic?.toLowerCase().contains(_searchQuery) ?? false;
                final lastMsgMatches =
                    c.lastMessageText?.toLowerCase().contains(_searchQuery) ?? false;
                return nameMatches || topicMatches || lastMsgMatches;
              }).toList();

              final regularChannels = filtered.where((c) => !c.isDM).toList();
              final directMessages = filtered.where((c) => c.isDM).toList();

              if (_activeFilter == _ChatFilter.channels) {
                directMessages.clear();
              } else if (_activeFilter == _ChatFilter.directMessages) {
                regularChannels.clear();
              }

              if (regularChannels.isEmpty && directMessages.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.forum_outlined,
                            size: 52,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No chats matching "$_searchQuery"'
                                : 'No channels found',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try searching with a different term'
                                : 'Start collaborating by creating a channel or direct message.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () =>
                                  _showCreateChannelDialog(context, workspace.id),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Create First Channel'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Section: Channels
                    if (regularChannels.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CHANNELS (${regularChannels.length})',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showCreateChannelDialog(context, workspace.id),
                            child: const Text(
                              '+ New Channel',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ...regularChannels.map((c) => _ChannelListItem(
                            channel: c,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChannelChatScreen(channel: c),
                              ),
                            ),
                          )),
                      const SizedBox(height: 20),
                    ],

                    // Section: Direct Messages
                    if (directMessages.isNotEmpty || _activeFilter == _ChatFilter.directMessages) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DIRECT MESSAGES (${directMessages.length})',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showStartDMDialog(
                                workspace.id, currentUser?.id ?? ''),
                            child: const Text(
                              '+ Start DM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (directMessages.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEDE9E3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.mark_chat_unread_outlined,
                                  color: AppColors.textSecondary, size: 22),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No direct messages yet.\nTap "+ Start DM" to chat with any member.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...directMessages.map((dm) => _ChannelListItem(
                              channel: dm,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChannelChatScreen(channel: dm),
                                ),
                              ),
                            )),
                    ],
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFEDE9E3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ChannelListItem extends StatelessWidget {
  final ChannelModel channel;
  final VoidCallback onTap;

  const _ChannelListItem({
    required this.channel,
    required this.onTap,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();

    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      return '${local.month}/${local.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDM = channel.isDM;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE9E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar / Hashtag icon
                Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isDM
                            ? const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isDM ? const Color(0xFF6366F1) : AppColors.primary)
                                .withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isDM
                            ? (channel.name.isNotEmpty
                                ? channel.name[0].toUpperCase()
                                : '@')
                            : '#',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (isDM)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name and last message preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              isDM ? channel.name : '#${channel.name}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (channel.lastMessageTime != null)
                            Text(
                              _formatTime(channel.lastMessageTime),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        channel.lastMessageText?.isNotEmpty == true
                            ? '${channel.lastMessageSender != null ? "${channel.lastMessageSender}: " : ""}${channel.lastMessageText}'
                            : (channel.topic?.isNotEmpty == true
                                ? channel.topic!
                                : 'No messages yet. Tap to start chatting.'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: channel.lastMessageText != null
                              ? AppColors.textPrimary.withValues(alpha: 0.85)
                              : AppColors.textSecondary.withValues(alpha: 0.65),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFD1D5DB),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
