import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/channel_model.dart';
import '../providers/chat_providers.dart';
import 'channel_chat_screen.dart';

class TeamChannelDetailScreen extends ConsumerStatefulWidget {
  final ChannelModel channel;

  const TeamChannelDetailScreen({
    super.key,
    required this.channel,
  });

  @override
  ConsumerState<TeamChannelDetailScreen> createState() => _TeamChannelDetailScreenState();
}

class _TeamChannelDetailScreenState extends ConsumerState<TeamChannelDetailScreen> {
  bool _notificationsMuted = false;
  final String _searchQuery = '';

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = date is DateTime ? date : DateTime.parse(date.toString());
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  Future<void> _startDirectMessage(BuildContext context, String targetUserId, String targetName) async {
    try {
      final dmChannel = await ref.read(chatRepositoryProvider).getOrCreateDM(
            widget.channel.workspaceId,
            targetUserId,
          );
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChannelChatScreen(channel: dmChannel),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start direct chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(channelDetailsProvider(widget.channel.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '#${widget.channel.name}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: detailsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Could not load channel details\n$err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(channelDetailsProvider(widget.channel.id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final name = data['name']?.toString() ?? widget.channel.name;
          final topic = data['topic']?.toString() ?? widget.channel.topic ?? '';
          final workspaceName = data['workspaceName']?.toString() ?? 'Workspace';
          final totalMessages = data['totalMessages'] ?? widget.channel.totalMessages;
          final isPrivate = data['type']?.toString().toUpperCase() == 'PRIVATE';
          final rawMembers = data['members'] as List<dynamic>? ?? [];

          final members = rawMembers.map((m) => Map<String, dynamic>.from(m as Map)).toList();

          final filteredMembers = _searchQuery.isEmpty
              ? members
              : members.where((m) {
                  final mName = m['name']?.toString().toLowerCase() ?? '';
                  final mEmail = m['email']?.toString().toLowerCase() ?? '';
                  final q = _searchQuery.toLowerCase();
                  return mName.contains(q) || mEmail.contains(q);
                }).toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel Hero Header (Teams Channel Profile)
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Column(
                    children: [
                      // Channel Icon
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: isPrivate
                              ? const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: (isPrivate ? const Color(0xFFF59E0B) : AppColors.primary)
                                  .withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          isPrivate ? Icons.lock_rounded : Icons.tag_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Channel Name
                      Text(
                        '#$name',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      // Channel Type Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPrivate ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPrivate ? Icons.lock_outline_rounded : Icons.public_rounded,
                              size: 13,
                              color: isPrivate ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPrivate ? 'Private Channel' : 'Public Channel',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isPrivate ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (topic.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          topic,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Quick Action Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderAction(
                        icon: _notificationsMuted
                            ? Icons.notifications_off_rounded
                            : Icons.notifications_active_rounded,
                        label: _notificationsMuted ? 'Muted' : 'Notifications',
                        isActive: !_notificationsMuted,
                        onTap: () {
                          setState(() {
                            _notificationsMuted = !_notificationsMuted;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _notificationsMuted
                                    ? 'Notifications muted for #$name'
                                    : 'Notifications enabled for #$name',
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      _buildHeaderAction(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Messages ($totalMessages)',
                        onTap: () => Navigator.pop(context),
                      ),
                      _buildHeaderAction(
                        icon: Icons.group_outlined,
                        label: '${members.length} Members',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Channel Info Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'About Channel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.corporate_fare_rounded, color: AppColors.primary, size: 20),
                          title: const Text('Workspace', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          subtitle: Text(workspaceName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.calendar_month_rounded, color: Color(0xFF10B981), size: 20),
                          title: const Text('Created On', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          subtitle: Text(_formatDate(data['createdAt']), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Members Section (Teams Style)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Team Members (${members.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${members.where((m) => m['isOnline'] == true).length} online',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Members List Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredMembers.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
                      itemBuilder: (ctx, i) {
                        final m = filteredMembers[i];
                        final mName = m['name']?.toString() ?? 'Member';
                        final mEmail = m['email']?.toString() ?? '';
                        final mRole = m['role']?.toString() ?? 'MEMBER';
                        final mOnline = m['isOnline'] == true;
                        final mId = m['id']?.toString() ?? '';

                        final mInitials = mName.isNotEmpty
                            ? mName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
                            : 'M';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  mInitials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: mOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            mName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            mEmail,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: mRole == 'OWNER'
                                      ? const Color(0xFFFEF3C7)
                                      : (mRole == 'ADMIN'
                                          ? const Color(0xFFEEF2FF)
                                          : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  mRole,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: mRole == 'OWNER'
                                        ? const Color(0xFFD97706)
                                        : (mRole == 'ADMIN'
                                            ? const Color(0xFF4F46E5)
                                            : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primary),
                                tooltip: 'Direct Message',
                                onPressed: () => _startDirectMessage(context, mId, mName),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive ? const Color(0xFF4F46E5) : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF4F46E5) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
