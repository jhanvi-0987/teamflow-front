import 'package:equatable/equatable.dart';

class MessageModel extends Equatable {
  final String id;
  final String channelId;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String content;
  final String? taskId;
  final String? taskTitle;
  final String? taskStatus;
  final String? taskPriority;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.content,
    this.taskId,
    this.taskTitle,
    this.taskStatus,
    this.taskPriority,
    required this.createdAt,
  });

  bool get hasLinkedTask => taskId != null && taskId!.isNotEmpty;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    final task = json['task'] as Map<String, dynamic>?;

    return MessageModel(
      id: json['id'] as String,
      channelId: json['channelId'] as String,
      senderId: json['senderId'] as String? ?? sender?['id'] as String? ?? '',
      senderName: sender?['name'] as String? ?? 'Team Member',
      senderEmail: sender?['email'] as String? ?? '',
      content: json['content'] as String? ?? '',
      taskId: json['taskId'] as String? ?? task?['id'] as String?,
      taskTitle: task?['title'] as String?,
      taskStatus: task?['status'] as String?,
      taskPriority: task?['priority'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        channelId,
        senderId,
        senderName,
        senderEmail,
        content,
        taskId,
        taskTitle,
        taskStatus,
        taskPriority,
        createdAt,
      ];
}
