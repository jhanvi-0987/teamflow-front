import 'package:equatable/equatable.dart';

class ReactionGroupModel extends Equatable {
  final String emoji;
  final int count;
  final List<String> userIds;
  final List<String> userNames;

  const ReactionGroupModel({
    required this.emoji,
    required this.count,
    required this.userIds,
    required this.userNames,
  });

  bool hasReacted(String userId) => userIds.contains(userId);

  factory ReactionGroupModel.fromJson(Map<String, dynamic> json) {
    return ReactionGroupModel(
      emoji: json['emoji'] as String? ?? '👍',
      count: (json['count'] as num?)?.toInt() ?? 0,
      userIds: (json['userIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      userNames: (json['userNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'count': count,
        'userIds': userIds,
        'userNames': userNames,
      };

  @override
  List<Object?> get props => [emoji, count, userIds, userNames];
}

