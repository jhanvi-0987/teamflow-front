import '../models/task_model.dart';
import '../models/comment_model.dart';
import '../models/subtask_model.dart';
import '../models/label_model.dart';

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

  // User search
  Future<List<UserSummary>> searchUsers(String query);

  // Subtasks
  Future<SubtaskModel> createSubtask(String taskId, String title, {double? position});
  Future<SubtaskModel> updateSubtask(
    String taskId,
    String subtaskId, {
    String? title,
    bool? isCompleted,
    double? position,
  });
  Future<void> deleteSubtask(String taskId, String subtaskId);

  // Labels
  Future<List<LabelModel>> listWorkspaceLabels(String workspaceId);
  Future<LabelModel> createWorkspaceLabel(String workspaceId, String name, String colorHex);
  Future<void> deleteWorkspaceLabel(String workspaceId, String labelId);
  Future<LabelModel> addLabelToTask(String taskId, String labelId);
  Future<void> removeLabelFromTask(String taskId, String labelId);
}

