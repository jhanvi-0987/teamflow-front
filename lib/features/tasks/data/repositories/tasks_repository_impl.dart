import '../../domain/models/task_model.dart';
import '../../domain/models/comment_model.dart';
import '../../domain/models/subtask_model.dart';
import '../../domain/models/label_model.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../datasources/tasks_remote_data_source.dart';

class TasksRepositoryImpl implements TasksRepository {
  final TasksRemoteDataSource remoteDataSource;

  TasksRepositoryImpl({required this.remoteDataSource});

  @override
  Future<TaskModel> createTask({
    required String projectId,
    required String title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    DateTime? dueAt,
    double? position,
  }) {
    return remoteDataSource.createTask(
      projectId: projectId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      assigneeId: assigneeId,
      dueAt: dueAt,
      position: position,
    );
  }

  @override
  Future<List<TaskModel>> listTasks(
    String projectId, {
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    String? search,
  }) {
    return remoteDataSource.listTasks(
      projectId,
      status: status,
      priority: priority,
      assigneeId: assigneeId,
      search: search,
    );
  }

  @override
  Future<TaskModel> getTaskById(String taskId) {
    return remoteDataSource.getTaskById(taskId);
  }

  @override
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
  }) {
    return remoteDataSource.updateTask(
      taskId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      assigneeId: assigneeId,
      dueAt: dueAt,
      position: position,
      version: version,
    );
  }

  @override
  Future<TaskModel> transitionStatus(
    String taskId,
    TaskStatus status, {
    double? position,
    int? version,
  }) {
    return remoteDataSource.transitionStatus(
      taskId,
      status,
      position: position,
      version: version,
    );
  }

  @override
  Future<void> deleteTask(String taskId) {
    return remoteDataSource.deleteTask(taskId);
  }

  @override
  Future<CommentModel> createComment(String taskId, String body) {
    return remoteDataSource.createComment(taskId, body);
  }

  @override
  Future<List<CommentModel>> listComments(String taskId) {
    return remoteDataSource.listComments(taskId);
  }

  @override
  Future<void> deleteComment(String commentId) {
    return remoteDataSource.deleteComment(commentId);
  }

  @override
  Future<List<UserSummary>> searchUsers(String query) {
    return remoteDataSource.searchUsers(query);
  }

  // --- SUBTASKS ---

  @override
  Future<SubtaskModel> createSubtask(
    String taskId,
    String title, {
    double? position,
  }) {
    return remoteDataSource.createSubtask(taskId, title, position: position);
  }

  @override
  Future<SubtaskModel> updateSubtask(
    String taskId,
    String subtaskId, {
    String? title,
    bool? isCompleted,
    double? position,
  }) {
    return remoteDataSource.updateSubtask(
      taskId,
      subtaskId,
      title: title,
      isCompleted: isCompleted,
      position: position,
    );
  }

  @override
  Future<void> deleteSubtask(String taskId, String subtaskId) {
    return remoteDataSource.deleteSubtask(taskId, subtaskId);
  }

  // --- LABELS ---

  @override
  Future<List<LabelModel>> listWorkspaceLabels(String workspaceId) {
    return remoteDataSource.listWorkspaceLabels(workspaceId);
  }

  @override
  Future<LabelModel> createWorkspaceLabel(
    String workspaceId,
    String name,
    String colorHex,
  ) {
    return remoteDataSource.createWorkspaceLabel(workspaceId, name, colorHex);
  }

  @override
  Future<void> deleteWorkspaceLabel(String workspaceId, String labelId) {
    return remoteDataSource.deleteWorkspaceLabel(workspaceId, labelId);
  }

  @override
  Future<LabelModel> addLabelToTask(String taskId, String labelId) {
    return remoteDataSource.addLabelToTask(taskId, labelId);
  }

  @override
  Future<void> removeLabelFromTask(String taskId, String labelId) {
    return remoteDataSource.removeLabelFromTask(taskId, labelId);
  }
}

