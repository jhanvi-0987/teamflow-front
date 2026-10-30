import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../tasks/domain/models/task_model.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../../domain/models/channel_model.dart';
import '../../domain/models/message_model.dart';
import '../providers/chat_providers.dart';
import '../providers/chat_notification_providers.dart';
import '../../../projects/presentation/providers/project_providers.dart';
import 'user_profile_detail_screen.dart';
import 'team_channel_detail_screen.dart';
import '../../domain/models/call_session_model.dart';
import '../providers/call_providers.dart';
import 'voice_call_screen.dart';
import 'video_call_screen.dart';

class ChannelChatScreen extends ConsumerStatefulWidget {
  final ChannelModel channel;

  const ChannelChatScreen({
    super.key,
    required this.channel,
  });

  @override
  ConsumerState<ChannelChatScreen> createState() => _ChannelChatScreenState();
}

class _ChannelChatScreenState extends ConsumerState<ChannelChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  Timer? _typingDebounce;
  bool _isTyping = false;
  String? _selectedTaskId;
  String? _selectedTaskTitle;
  MessageModel? _replyingToMessage;
  late final StateController<String?> _activeChannelNotifier;
  late final SocketService _socketService;

  @override
  void initState() {
    super.initState();
    // Cached because `ref` cannot be used in dispose() once the element is torn down.
    _activeChannelNotifier = ref.read(activeChatChannelProvider.notifier);
    _socketService = ref.read(socketServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(activeChatChannelProvider.notifier).state = widget.channel.id;
        ref.read(unreadMessagesProvider.notifier).markChannelAsRead(widget.channel.id);
        ref.read(chatRepositoryProvider).markAsRead(widget.channel.id).catchError((_) {});
        ref.read(channelMessagesProvider(widget.channel.id).notifier).loadMessages();
      }
    });
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    final activeNotifier = _activeChannelNotifier;
    final channelId = widget.channel.id;
    _socketService.leaveChannel(channelId);
    // Deferred: provider state can't change while the widget tree is finalizing.
    Future.microtask(() {
      if (activeNotifier.mounted && activeNotifier.state == channelId) {
        activeNotifier.state = null;
      }
    });
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      ref
          .read(channelMessagesProvider(widget.channel.id).notifier)
          .setTyping(true);
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 1500), () {
      if (_isTyping) {
        _isTyping = false;
        ref
            .read(channelMessagesProvider(widget.channel.id).notifier)
            .setTyping(false);
      }
    });
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(0.0);
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedTaskId == null) return;

    final content = text.isNotEmpty ? text : 'Referenced a task';
    final taskId = _selectedTaskId;
    final replyToId = _replyingToMessage?.id;

    _textController.clear();
    setState(() {
      _selectedTaskId = null;
      _selectedTaskTitle = null;
      _replyingToMessage = null;
    });

    if (_isTyping) {
      _isTyping = false;
      ref
          .read(channelMessagesProvider(widget.channel.id).notifier)
          .setTyping(false);
    }

    final success = await ref
        .read(channelMessagesProvider(widget.channel.id).notifier)
        .sendMessage(content, taskId: taskId, replyToId: replyToId);

    if (success) {
      _scrollToBottom();
    }
  }

  void _showForwardDialog(BuildContext context, MessageModel message) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ForwardChannelPickerSheet(
        workspaceId: widget.channel.workspaceId,
        currentChannelId: widget.channel.id,
        onChannelSelected: (targetChannel) async {
          Navigator.of(ctx).pop();
          final success = await ref
              .read(channelMessagesProvider(widget.channel.id).notifier)
              .forwardMessage(message.id, targetChannel.id);
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Forwarded to ${targetChannel.isDM ? targetChannel.name : '#${targetChannel.name}'}'
                      : 'Failed to forward message',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showPinnedMessagesSheet(
      BuildContext context, List<MessageModel> pinnedMessages) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.push_pin_rounded,
                    color: Color(0xFFD97706), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Pinned Messages (${pinnedMessages.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: pinnedMessages.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final msg = pinnedMessages[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          msg.senderName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          tooltip: 'Unpin message',
                          onPressed: () {
                            ref
                                .read(channelMessagesProvider(widget.channel.id)
                                    .notifier)
                                .togglePinMessage(msg.id);
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ],
                    ),
                    subtitle: Text(
                      msg.content,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetailsScreen(BuildContext context) {
    if (widget.channel.isDM) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UserProfileDetailScreen(channel: widget.channel),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TeamChannelDetailScreen(channel: widget.channel),
        ),
      );
    }
  }

  void _showTaskPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TaskPickerSheet(
        workspaceId: widget.channel.workspaceId,
        onTaskSelected: (task) {
          setState(() {
            _selectedTaskId = task.id;
            _selectedTaskTitle = task.title;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(channelMessagesProvider(widget.channel.id));
    final typingUser = ref.watch(channelTypingProvider(widget.channel.id)).value;
    final currentUser = ref.watch(authControllerProvider).user;
    final pinnedMessages = ref.watch(channelPinnedMessagesProvider(widget.channel.id));

    // Auto-scroll to bottom only when new incoming messages arrive
    ref.listen(channelMessagesProvider(widget.channel.id), (prev, next) {
      if (prev?.hasValue == true && next.hasValue) {
        final prevCount = prev!.value?.length ?? 0;
        final nextCount = next.value?.length ?? 0;
        if (nextCount > prevCount) {
          if (_scrollController.hasClients && _scrollController.offset < 150) {
            _scrollToBottom(animate: true);
          }
        }
      }
    });

    final isDM = widget.channel.isDM;
    final channelDisplayName = widget.channel.getDisplayName(currentUser?.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: InkWell(
          onTap: () => _openDetailsScreen(context),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: isDM
                        ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          )
                        : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isDM
                        ? (channelDisplayName.isNotEmpty
                            ? channelDisplayName[0].toUpperCase()
                            : '@')
                        : '#',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDM ? channelDisplayName : '#${widget.channel.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.channel.topic?.isNotEmpty == true
                            ? widget.channel.topic!
                            : (isDM ? 'Tap for contact info' : 'Tap for team details'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.call_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
            tooltip: 'Voice Call',
            onPressed: () {
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
                    channelId: widget.channel.id,
                    channelName: channelDisplayName,
                    type: CallType.voice,
                  );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VoiceCallScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.videocam_rounded,
              color: AppColors.textPrimary,
              size: 24,
            ),
            tooltip: 'Video Call',
            onPressed: () {
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
                    channelId: widget.channel.id,
                    channelName: channelDisplayName,
                    type: CallType.video,
                  );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VideoCallScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
            tooltip: isDM ? 'User Profile' : 'Channel Details',
            onPressed: () => _openDetailsScreen(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Pinned Messages Banner
          if (pinnedMessages.isNotEmpty)
            InkWell(
              onTap: () => _showPinnedMessagesSheet(context, pinnedMessages),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  border: Border(
                    bottom: BorderSide(
                        color: const Color(0xFFFDE68A).withValues(alpha: 0.8)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.push_pin_rounded,
                        size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${pinnedMessages.length} Pinned ${pinnedMessages.length == 1 ? 'Message' : 'Messages'}: ${pinnedMessages.last.content}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: Color(0xFF92400E)),
                  ],
                ),
              ),
            ),

          // Message List
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load messages\n$err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(channelMessagesProvider(widget.channel.id)
                                .notifier)
                            .loadMessages(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isDM
                                ? 'Start of direct conversation'
                                : 'Welcome to #${widget.channel.name}!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Send a message or link a task to begin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];
                    final isMe =
                        currentUser != null && msg.senderId == currentUser.id;

                    return _MessageBubble(
                      key: ValueKey(
                          '${msg.id}_${msg.status}_${msg.isPinned}_${msg.reactions.fold<int>(0, (acc, r) => acc + r.count)}_${msg.readAt?.millisecondsSinceEpoch}'),
                      message: msg,
                      isMe: isMe,
                      onReply: (m) {
                        setState(() {
                          _replyingToMessage = m;
                        });
                        _focusNode.requestFocus();
                      },
                      onForward: (m) => _showForwardDialog(context, m),
                    );
                  },
                );
              },
            ),
          ),

          // Live typing indicator
          if (typingUser != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$typingUser is typing...',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          // Selected Task Preview Pill (if user linked a task)
          if (_selectedTaskTitle != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded,
                      size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Linked Task: $_selectedTaskTitle',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF15803D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedTaskId = null;
                      _selectedTaskTitle = null;
                    }),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

          // Quoted Reply Preview Bar
          if (_replyingToMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: AppColors.primary, width: 4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Replying to ${_replyingToMessage!.senderName}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          _replyingToMessage!.content,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _replyingToMessage = null),
                    child:
                        const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Link Task Button
                  IconButton(
                    icon: const Icon(Icons.add_task_rounded,
                        color: AppColors.primary),
                    tooltip: 'Link a Task to Chat',
                    onPressed: () => _showTaskPicker(context),
                  ),

                  // Text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        onChanged: _onTextChanged,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: isDM
                              ? 'Message $channelDisplayName...'
                              : 'Message #${widget.channel.name}...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  final MessageModel message;
  final bool isMe;
  final ValueChanged<MessageModel>? onReply;
  final ValueChanged<MessageModel>? onForward;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onForward,
  });

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showMessageActionSheet(
    BuildContext context,
    WidgetRef ref,
    String? currentUserId,
  ) {
    const emojis = ['👍', '❤️', '🎉', '🚀', '👀', '🔥'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Quick Emojis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: emojis.map((emoji) {
                final existing = message.reactions
                    .where((r) => r.emoji == emoji)
                    .toList();
                final isSelected = currentUserId != null &&
                    existing.isNotEmpty &&
                    existing.first.hasReacted(currentUserId);

                return InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref
                        .read(
                            channelMessagesProvider(message.channelId).notifier)
                        .toggleReaction(message.id, emoji);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : null,
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 24),

            // 1. Reply
            ListTile(
              dense: true,
              leading:
                  const Icon(Icons.reply_rounded, color: AppColors.primary),
              title: const Text('Reply',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(ctx).pop();
                onReply?.call(message);
              },
            ),

            // 2. Copy Text
            ListTile(
              dense: true,
              leading:
                  const Icon(Icons.copy_rounded, color: AppColors.textPrimary),
              title: const Text('Copy Text',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(ctx).pop();
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),

            // 3. Pin / Unpin
            ListTile(
              dense: true,
              leading: Icon(
                message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: const Color(0xFFD97706),
              ),
              title: Text(
                message.isPinned ? 'Unpin Message' : 'Pin Message',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(channelMessagesProvider(message.channelId).notifier)
                    .togglePinMessage(message.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      message.isPinned
                          ? 'Message unpinned'
                          : 'Message pinned to channel',
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),

            // 4. Forward
            ListTile(
              dense: true,
              leading:
                  const Icon(Icons.forward_rounded, color: Color(0xFF2563EB)),
              title: const Text('Forward',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(ctx).pop();
                onForward?.call(message);
              },
            ),

            // 5. Delete (if author)
            if (isMe)
              ListTile(
                dense: true,
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: const Text(
                  'Delete Message',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.error),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Delete Message'),
                      content: const Text(
                        'Are you sure you want to delete this message? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dCtx).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(dCtx).pop();
                            ref
                                .read(
                                    channelMessagesProvider(message.channelId)
                                        .notifier)
                                .deleteMessage(message.id);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTicks() {
    if (!isMe) return const SizedBox.shrink();

    final isRead =
        message.status.toLowerCase() == 'read' || message.readAt != null;
    final isDelivered = message.status.toLowerCase() == 'delivered' ||
        message.deliveredAt != null;

    if (isRead) {
      // Double tick mark with blue color when recipient has read the message
      return const Icon(
        Icons.done_all_rounded,
        size: 15,
        color: Color(0xFF38BDF8),
      );
    } else if (isDelivered) {
      // Two tick marks with gray color when recipient is online/message delivered
      return Icon(
        Icons.done_all_rounded,
        size: 15,
        color: Colors.white.withValues(alpha: 0.7),
      );
    } else {
      // One tick mark when recipient is offline
      return Icon(
        Icons.check_rounded,
        size: 14,
        color: Colors.white.withValues(alpha: 0.7),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authControllerProvider).user?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE0E7FF),
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF4338CA),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                GestureDetector(
                  onLongPress: () =>
                      _showMessageActionSheet(context, ref, currentUserId),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isMe ? AppColors.primaryGradient : null,
                      color: isMe ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe
                            ? const Radius.circular(16)
                            : const Radius.circular(2),
                        bottomRight: isMe
                            ? const Radius.circular(2)
                            : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        // Quoted Reply Preview inside bubble
                        if (message.isReply && message.replyTo != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color:
                                      isMe ? Colors.white : AppColors.primary,
                                  width: 3.5,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.reply_rounded,
                                      size: 13,
                                      color: isMe
                                          ? Colors.white
                                          : AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      message.replyTo!.senderName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isMe
                                            ? Colors.white
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  message.replyTo!.content,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isMe
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Forwarded indicator
                        if (message.isForwarded) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.forward_rounded,
                                size: 12,
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Forwarded',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: isMe
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],

                        // Text content
                        Text(
                          message.content,
                          style: TextStyle(
                            color: isMe ? Colors.white : AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),

                        // Embedded Interactive Task Card
                        if (message.hasLinkedTask) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              if (message.taskId != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TaskDetailScreen(
                                      taskId: message.taskId!,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isMe
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 18,
                                    color: isMe
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.taskTitle ?? 'Linked Task',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isMe
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (message.taskStatus != null)
                                          Text(
                                            'Status: ${message.taskStatus}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isMe
                                                  ? Colors.white
                                                      .withValues(alpha: 0.8)
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: isMe
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.isPinned) ...[
                              Icon(
                                Icons.push_pin_rounded,
                                size: 12,
                                color: isMe
                                    ? Colors.amber.shade200
                                    : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              _formatTime(message.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppColors.textSecondary
                                        .withValues(alpha: 0.6),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              _buildStatusTicks(),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Reaction chips
                if (message.hasReactions) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
                    children: [
                      ...message.reactions.map((reaction) {
                        final hasReacted = currentUserId != null &&
                            reaction.hasReacted(currentUserId);
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            ref
                                .read(channelMessagesProvider(message.channelId)
                                    .notifier)
                                .toggleReaction(message.id, reaction.emoji);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: hasReacted
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasReacted
                                    ? AppColors.primary.withValues(alpha: 0.6)
                                    : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  reaction.emoji,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${reaction.count}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: hasReacted
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            _showMessageActionSheet(context, ref, currentUserId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(
                            Icons.add_reaction_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForwardChannelPickerSheet extends ConsumerWidget {
  final String workspaceId;
  final String currentChannelId;
  final ValueChanged<ChannelModel> onChannelSelected;

  const _ForwardChannelPickerSheet({
    required this.workspaceId,
    required this.currentChannelId,
    required this.onChannelSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(workspaceChannelsProvider(workspaceId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Forward Message To',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: channelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Failed to load channels: $err')),
              data: (channels) {
                final targetChannels =
                    channels.where((c) => c.id != currentChannelId).toList();
                if (targetChannels.isEmpty) {
                  return const Center(
                    child:
                        Text('No other channels available in this workspace'),
                  );
                }
                return ListView.separated(
                  itemCount: targetChannels.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final ch = targetChannels[i];
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: ch.isDM
                              ? const Color(0xFFEEF2FF)
                              : AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            ch.isDM
                                ? Icons.person_outline_rounded
                                : Icons.tag_rounded,
                            size: 18,
                            color: ch.isDM
                                ? const Color(0xFF4F46E5)
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        ch.isDM ? ch.name : '#${ch.name}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: ch.topic?.isNotEmpty == true
                          ? Text(ch.topic!, maxLines: 1)
                          : null,
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Colors.grey),
                      onTap: () => onChannelSelected(ch),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskPickerSheet extends ConsumerWidget {
  final String workspaceId;
  final ValueChanged<TaskModel> onTaskSelected;

  const _TaskPickerSheet({
    required this.workspaceId,
    required this.onTaskSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(workspaceProjectsProvider(workspaceId)).value ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select Task to Mention in Chat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: projects.isEmpty
                ? const Center(child: Text('No active projects found.'))
                : ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, i) {
                      final project = projects[i];
                      return _ProjectTasksList(
                        projectId: project.id,
                        projectName: project.name,
                        onTaskSelected: (task) {
                          onTaskSelected(task);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProjectTasksList extends ConsumerWidget {
  final String projectId;
  final String projectName;
  final ValueChanged<TaskModel> onTaskSelected;

  const _ProjectTasksList({
    required this.projectId,
    required this.projectName,
    required this.onTaskSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(projectTasksProvider(projectId));

    return tasksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox.shrink();
        return ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            projectName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          children: tasks.map((task) {
            return ListTile(
              dense: true,
              leading: const Icon(Icons.task_alt, color: AppColors.primary, size: 20),
              title: Text(task.title),
              subtitle: Text(task.status.name.toUpperCase()),
              trailing: const Icon(Icons.add, size: 18),
              onTap: () => onTaskSelected(task),
            );
          }).toList(),
        );
      },
    );
  }
}
