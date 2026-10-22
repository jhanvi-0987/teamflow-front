import '../models/task_model.dart';
import '../models/comment_model.dart';

abstract class TasksRepository {
  Future<TaskModel> createTask({
    required String projectId,
    required String title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    DateTime? dueAt,
    double? position,
  });

  Future<List<TaskModel>> listTasks(
    String projectId, {
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    String? search,
  });

  Future<TaskModel> getTaskById(String taskId);

  Future<TaskModel> updateTask(
    String taskId, {
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    DateTime? dueAt,
    double? position,
    int? version,
  });

  Future<TaskModel> transitionStatus(
    String taskId,
    TaskStatus status, {
    double? position,
    int? version,
  });

  Future<void> deleteTask(String taskId);

  // Comments
  Future<CommentModel> createComment(String taskId, String body);
  Future<List<CommentModel>> listComments(String taskId);
  Future<void> deleteComment(String commentId);
}
