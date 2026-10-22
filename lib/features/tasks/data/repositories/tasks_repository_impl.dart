import '../../domain/models/task_model.dart';
import '../../domain/models/comment_model.dart';
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
}
