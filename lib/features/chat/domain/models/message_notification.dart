import 'package:equatable/equatable.dart';

class MessageNotification extends Equatable {
  final String? messageId;
  final String channelId;
  final String channelName;
  final bool isDM;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String content;
  final String? taskId;
  final String? taskTitle;
  final String workspaceId;
  final DateTime createdAt;

  const MessageNotification({
    this.messageId,
    required this.channelId,
    required this.channelName,
    required this.isDM,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.content,
    this.taskId,
    this.taskTitle,
    required this.workspaceId,
    required this.createdAt,
  });

  factory MessageNotification.fromJson(Map<String, dynamic> json) {
    final isDMVal = json['isDM'] == true || json['isDM'] == 'true';
    return MessageNotification(
      messageId: json['messageId'] as String?,
      channelId: json['channelId'] as String? ?? '',
      channelName: json['channelName'] as String? ??
          (isDMVal ? 'Direct Message' : 'Channel'),
      isDM: isDMVal,
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? json['senderEmail'] as String? ?? 'Teammate',
      senderEmail: json['senderEmail'] as String? ?? '',
      content: json['content'] as String? ?? '',
      taskId: json['taskId'] as String?,
      taskTitle: json['taskTitle'] as String?,
      workspaceId: json['workspaceId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        messageId,
        channelId,
        channelName,
        isDM,
        senderId,
        senderName,
        senderEmail,
        content,
        taskId,
        taskTitle,
        workspaceId,
        createdAt,
      ];
}
