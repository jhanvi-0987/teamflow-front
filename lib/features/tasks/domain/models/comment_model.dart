import 'package:equatable/equatable.dart';
import 'task_model.dart';

class CommentModel extends Equatable {
  final String id;
  final String taskId;
  final String authorId;
  final String body;
  final UserSummary author;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommentModel({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.body,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      authorId: json['authorId'] as String,
      body: json['body'] as String,
      author: UserSummary.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        authorId,
        body,
        author,
        createdAt,
        updatedAt,
      ];
}
