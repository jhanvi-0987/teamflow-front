import 'package:equatable/equatable.dart';

enum ChannelType {
  public,
  private,
  directMessage;

  static ChannelType fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PRIVATE':
        return ChannelType.private;
      case 'DIRECT_MESSAGE':
        return ChannelType.directMessage;
      case 'PUBLIC':
      default:
        return ChannelType.public;
    }
  }

  String toApiString() {
    switch (this) {
      case ChannelType.private:
        return 'PRIVATE';
      case ChannelType.directMessage:
        return 'DIRECT_MESSAGE';
      case ChannelType.public:
        return 'PUBLIC';
    }
  }
}

class ChannelModel extends Equatable {
  final String id;
  final String workspaceId;
  final String name;
  final String? topic;
  final ChannelType type;
  final int membersCount;
  final int totalMessages;
  final String? lastMessageText;
  final String? lastMessageSender;
  final DateTime? lastMessageTime;
  final DateTime updatedAt;

  const ChannelModel({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.topic,
    required this.type,
    this.membersCount = 0,
    this.totalMessages = 0,
    this.lastMessageText,
    this.lastMessageSender,
    this.lastMessageTime,
    required this.updatedAt,
  });

  bool get isDM => type == ChannelType.directMessage;
  bool get isPrivate => type == ChannelType.private;

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    final lastMsg = json['lastMessage'] as Map<String, dynamic>?;
    final sender = lastMsg?['sender'] as Map<String, dynamic>?;

    return ChannelModel(
      id: json['id'] as String,
      workspaceId: json['workspaceId'] as String,
      name: json['name'] as String? ?? 'General',
      topic: json['topic'] as String?,
      type: ChannelType.fromString(json['type'] as String?),
      membersCount: json['membersCount'] as int? ?? 0,
      totalMessages: json['totalMessages'] as int? ?? 0,
      lastMessageText: lastMsg?['content'] as String?,
      lastMessageSender: sender?['name'] as String? ?? sender?['email'] as String?,
      lastMessageTime: lastMsg?['createdAt'] != null
          ? DateTime.tryParse(lastMsg!['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        workspaceId,
        name,
        topic,
        type,
        membersCount,
        totalMessages,
        lastMessageText,
        lastMessageSender,
        lastMessageTime,
        updatedAt,
      ];
}
