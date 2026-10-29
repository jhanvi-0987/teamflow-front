import 'package:equatable/equatable.dart';

class SubtaskModel extends Equatable {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final double position;
  final DateTime? createdAt;

  const SubtaskModel({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.position = 0,
    this.createdAt,
  });

  factory SubtaskModel.fromJson(Map<String, dynamic> json) {
    return SubtaskModel(
      id: json['id'] as String,
      taskId: json['taskId'] as String? ?? '',
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      position: (json['position'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'title': title,
        'isCompleted': isCompleted,
        'position': position,
      };

  SubtaskModel copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
    double? position,
    DateTime? createdAt,
  }) {
    return SubtaskModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, taskId, title, isCompleted, position];
}

