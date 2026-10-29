import 'package:equatable/equatable.dart';
import 'reaction_model.dart';

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
  final String status; // 'sent' | 'delivered' | 'read'
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<ReactionGroupModel> reactions;
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
    this.status = 'sent',
    this.deliveredAt,
    this.readAt,
    this.reactions = const [],
    required this.createdAt,
  });

  bool get hasLinkedTask => taskId != null && taskId!.isNotEmpty;
  bool get hasReactions => reactions.isNotEmpty;

  MessageModel copyWith({
    String? id,
    String? channelId,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? content,
    String? taskId,
    String? taskTitle,
    String? taskStatus,
    String? taskPriority,
    String? status,
    DateTime? deliveredAt,
    DateTime? readAt,
    List<ReactionGroupModel>? reactions,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      content: content ?? this.content,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      taskStatus: taskStatus ?? this.taskStatus,
      taskPriority: taskPriority ?? this.taskPriority,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    final task = json['task'] as Map<String, dynamic>?;
    final reactionsList = json['reactions'] as List<dynamic>?;

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
      status: json['status'] as String? ?? 'sent',
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'] as String)
          : null,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
      reactions: reactionsList != null
          ? reactionsList
              .map((e) => ReactionGroupModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'channelId': channelId,
        'senderId': senderId,
        'senderName': senderName,
        'senderEmail': senderEmail,
        'content': content,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'taskStatus': taskStatus,
        'taskPriority': taskPriority,
        'status': status,
        'deliveredAt': deliveredAt?.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

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
        status,
        deliveredAt,
        readAt,
        reactions,
        createdAt,
      ];
}
