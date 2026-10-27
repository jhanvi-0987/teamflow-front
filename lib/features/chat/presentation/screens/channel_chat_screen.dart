import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../tasks/domain/models/task_model.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../../domain/models/channel_model.dart';
import '../../domain/models/message_model.dart';
import '../providers/chat_providers.dart';
import '../../../projects/presentation/providers/project_providers.dart';

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
  Timer? _typingDebounce;
  bool _isTyping = false;
  String? _selectedTaskId;
  String? _selectedTaskTitle;

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _textController.dispose();
    _scrollController.dispose();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedTaskId == null) return;

    final content = text.isNotEmpty ? text : 'Referenced a task';
    final taskId = _selectedTaskId;

    _textController.clear();
    setState(() {
      _selectedTaskId = null;
      _selectedTaskTitle = null;
    });

    if (_isTyping) {
      _isTyping = false;
      ref
          .read(channelMessagesProvider(widget.channel.id).notifier)
          .setTyping(false);
    }

    final success = await ref
        .read(channelMessagesProvider(widget.channel.id).notifier)
        .sendMessage(content, taskId: taskId);

    if (success) {
      _scrollToBottom();
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

    // Auto-scroll on new messages
    ref.listen(channelMessagesProvider(widget.channel.id), (_, next) {
      if (next.hasValue) {
        _scrollToBottom();
      }
    });

    final isDM = widget.channel.isDM;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
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
                    ? (widget.channel.name.isNotEmpty
                        ? widget.channel.name[0].toUpperCase()
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
                    isDM ? widget.channel.name : '#${widget.channel.name}',
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
                        : (isDM ? 'Direct conversation' : 'Team Channel'),
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
      body: Column(
        children: [
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe =
                        currentUser != null && msg.senderId == currentUser.id;

                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
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
                        onChanged: _onTextChanged,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: isDM
                              ? 'Message ${widget.channel.name}...'
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

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
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
                Container(
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
                                                ? Colors.white.withValues(alpha: 0.8)
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
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
