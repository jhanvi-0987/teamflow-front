import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/channel_model.dart';
import '../../domain/models/call_session_model.dart';
import '../providers/call_providers.dart';
import '../providers/chat_providers.dart';
import 'voice_call_screen.dart';
import 'video_call_screen.dart';

class UserProfileDetailScreen extends ConsumerWidget {
  final ChannelModel channel;
  final String? initialUserName;
  final String? initialUserEmail;

  const UserProfileDetailScreen({
    super.key,
    required this.channel,
    this.initialUserName,
    this.initialUserEmail,
  });

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(channelDetailsProvider(channel.id));

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
        title: const Text(
          'Contact Info',
          style: TextStyle(
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
                Text('Could not load profile\n$err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(channelDetailsProvider(channel.id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final otherUser = data['otherUser'] as Map<String, dynamic>? ?? {};
          final name = otherUser['name']?.toString() ??
              initialUserName ??
              channel.name;
          final email = otherUser['email']?.toString() ??
              initialUserEmail ??
              'No email provided';
          final role = otherUser['role']?.toString() ?? 'MEMBER';
          final isOnline = otherUser['isOnline'] == true;
          final workspaceName = data['workspaceName']?.toString() ?? 'Workspace';
          final totalMessages = data['totalMessages'] ?? channel.totalMessages;
          final memberSince = otherUser['userCreatedAt'] ?? data['createdAt'];

          final initials = name.isNotEmpty
              ? name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
              : 'U';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Microsoft Teams Hero Header
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Column(
                    children: [
                      // Avatar with Presence indicator
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? const Color(0xFF10B981) // Teams Available Green
                                    : const Color(0xFF94A3B8), // Teams Offline Grey
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      // Email
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Presence & Role Badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Presence Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isOnline ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOnline ? 'Available' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isOnline ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Quick Action Buttons Row (Teams Style: Chat, Call, Video, Email)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.chat_bubble_rounded,
                        label: 'Chat',
                        onTap: () => Navigator.pop(context),
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.call_rounded,
                        label: 'Audio',
                        onTap: () {
                          if (ref.read(callStateProvider).isActive) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('A call is already in progress'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          ref.read(callStateProvider.notifier).startCall(
                                channelId: channel.id,
                                channelName: name,
                                type: CallType.voice,
                                targetUserId: otherUser['id']?.toString(),
                                remoteUserName: name,
                              );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const VoiceCallScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.videocam_rounded,
                        label: 'Video',
                        onTap: () {
                          if (ref.read(callStateProvider).isActive) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('A call is already in progress'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          ref.read(callStateProvider.notifier).startCall(
                                channelId: channel.id,
                                channelName: name,
                                type: CallType.video,
                                targetUserId: otherUser['id']?.toString(),
                                remoteUserName: name,
                              );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const VideoCallScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.mail_rounded,
                        label: 'Email',
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: email));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied $email to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Details Card: Contact Information
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
                            'Contact Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                          ),
                          title: const Text('Email', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          subtitle: Text(
                            email,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: email));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Copied $email to clipboard'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(height: 1, indent: 60),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.badge_outlined, color: Color(0xFF8B5CF6), size: 20),
                          ),
                          title: const Text('Organization', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          subtitle: Text(
                            workspaceName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                        const Divider(height: 1, indent: 60),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF10B981), size: 20),
                          ),
                          title: const Text('Member Since', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          subtitle: Text(
                            _formatDate(memberSince),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Details Card: Conversation Stats
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
                            'Conversation Activity',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.forum_outlined, color: Color(0xFFF59E0B), size: 20),
                          ),
                          title: const Text('Total Messages Exchanged', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          subtitle: Text(
                            '$totalMessages messages',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
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

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Icon(icon, color: const Color(0xFF4F46E5), size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
