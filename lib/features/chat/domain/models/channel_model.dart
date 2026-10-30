import 'package:equatable/equatable.dart';

class ChannelMemberSummary extends Equatable {
  final String id;
  final String name;
  final String email;

  const ChannelMemberSummary({
    required this.id,
    required this.name,
    required this.email,
  });

  factory ChannelMemberSummary.fromJson(Map<String, dynamic> json) {
    return ChannelMemberSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
      };

  @override
  List<Object?> get props => [id, name, email];
}

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
  final List<ChannelMemberSummary> members;
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
    this.members = const [],
    required this.updatedAt,
  });

  bool get isDM => type == ChannelType.directMessage;
  bool get isPrivate => type == ChannelType.private;

  /// Returns the appropriate title for the channel:
  /// - For regular channels: '#channel-name' or 'channel-name'
  /// - For Direct Messages: the OTHER user's name (vice versa for each participant)
  String getDisplayName(String? currentUserId) {
    if (!isDM) return name;
    if (members.isNotEmpty && currentUserId != null && currentUserId.isNotEmpty) {
      final other = members.firstWhere(
        (m) => m.id != currentUserId,
        orElse: () => members.first,
      );
      if (other.id != currentUserId && other.name.isNotEmpty) {
        return other.name;
      }
    }
    return name;
  }

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    final lastMsg = json['lastMessage'] as Map<String, dynamic>?;
    final sender = lastMsg?['sender'] as Map<String, dynamic>?;
    final membersList = (json['members'] as List<dynamic>?)
            ?.map((m) => ChannelMemberSummary.fromJson(m as Map<String, dynamic>))
            .toList() ??
        const <ChannelMemberSummary>[];

    return ChannelModel(
      id: json['id'] as String,
      workspaceId: json['workspaceId'] as String,
      name: json['name'] as String? ?? 'General',
      topic: json['topic'] as String?,
      type: ChannelType.fromString(json['type'] as String?),
      membersCount: json['membersCount'] as int? ?? membersList.length,
      totalMessages: json['totalMessages'] as int? ?? 0,
      lastMessageText: lastMsg?['content'] as String?,
      lastMessageSender: sender?['name'] as String? ?? sender?['email'] as String?,
      lastMessageTime: lastMsg?['createdAt'] != null
          ? DateTime.tryParse(lastMsg!['createdAt'] as String)
          : null,
      members: membersList,
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
        members,
        updatedAt,
      ];
}
