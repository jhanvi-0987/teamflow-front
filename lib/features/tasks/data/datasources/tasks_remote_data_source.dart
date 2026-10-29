// ignore_for_file: use_null_aware_elements
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/task_model.dart';
import '../../domain/models/comment_model.dart';
import '../../domain/models/subtask_model.dart';
import '../../domain/models/label_model.dart';

abstract class TasksRemoteDataSource {
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

  // User search for assignment
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


class TasksRemoteDataSourceImpl implements TasksRemoteDataSource {
  final Dio dio;

  TasksRemoteDataSourceImpl({required this.dio});

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
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.projectTasks(projectId),
        data: {
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (status != null) 'status': status.value,
          if (priority != null) 'priority': priority.value,
          if (assigneeId != null) 'assigneeId': assigneeId,
          if (dueAt != null) 'dueAt': dueAt.toIso8601String(),
          if (position != null) 'position': position,
        },
      );
      return TaskModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<TaskModel>> listTasks(
    String projectId, {
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    String? search,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.projectTasks(projectId),
        queryParameters: {
          if (status != null) 'status': status.value,
          if (priority != null) 'priority': priority.value,
          if (assigneeId != null) 'assigneeId': assigneeId,
          if (search != null && search.isNotEmpty) 'search': search,
          'limit': 100,
        },
      );

      final data = response.data;
      final List<dynamic> list = data is Map ? (data['tasks'] ?? []) : data;
      return list
          .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<TaskModel> getTaskById(String taskId) async {
    try {
      final response = await dio.get(ApiEndpoints.task(taskId));
      return TaskModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
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
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (status != null) data['status'] = status.value;
      if (priority != null) data['priority'] = priority.value;
      if (assigneeId != null) data['assigneeId'] = assigneeId;
      if (dueAt != null) data['dueAt'] = dueAt.toIso8601String();
      if (position != null) data['position'] = position;
      if (version != null) data['version'] = version;

      final response = await dio.patch(
        ApiEndpoints.task(taskId),
        data: data,
      );
      return TaskModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<TaskModel> transitionStatus(
    String taskId,
    TaskStatus status, {
    double? position,
    int? version,
  }) async {
    try {
      final response = await dio.patch(
        ApiEndpoints.taskStatus(taskId),
        data: {
          'status': status.value,
          if (position != null) 'position': position,
          if (version != null) 'version': version,
        },
      );
      return TaskModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await dio.delete(ApiEndpoints.task(taskId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<CommentModel> createComment(String taskId, String body) async {
    try {
      final response = await dio.post(
        ApiEndpoints.taskComments(taskId),
        data: {'body': body},
      );
      return CommentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<CommentModel>> listComments(String taskId) async {
    try {
      final response = await dio.get(ApiEndpoints.taskComments(taskId));
      final list = response.data as List<dynamic>;
      return list
          .map((item) => CommentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteComment(String commentId) async {
    try {
      await dio.delete(ApiEndpoints.comment(commentId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<UserSummary>> searchUsers(String query) async {
    try {
      final response = await dio.get(ApiEndpoints.searchUsers(query));
      final list = response.data as List<dynamic>;
      return list
          .map((item) => UserSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- SUBTASKS ---

  @override
  Future<SubtaskModel> createSubtask(
    String taskId,
    String title, {
    double? position,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.taskSubtasks(taskId),
        data: {
          'title': title,
          if (position != null) 'position': position,
        },
      );
      return SubtaskModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<SubtaskModel> updateSubtask(
    String taskId,
    String subtaskId, {
    String? title,
    bool? isCompleted,
    double? position,
  }) async {
    try {
      final response = await dio.patch(
        ApiEndpoints.taskSubtask(taskId, subtaskId),
        data: {
          if (title != null) 'title': title,
          if (isCompleted != null) 'isCompleted': isCompleted,
          if (position != null) 'position': position,
        },
      );
      return SubtaskModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    try {
      await dio.delete(ApiEndpoints.taskSubtask(taskId, subtaskId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- LABELS ---

  @override
  Future<List<LabelModel>> listWorkspaceLabels(String workspaceId) async {
    try {
      final response = await dio.get(ApiEndpoints.workspaceLabels(workspaceId));
      final list = response.data as List<dynamic>;
      return list
          .map((item) => LabelModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<LabelModel> createWorkspaceLabel(
    String workspaceId,
    String name,
    String colorHex,
  ) async {
    try {
      final response = await dio.post(
        ApiEndpoints.workspaceLabels(workspaceId),
        data: {
          'name': name,
          'color': colorHex,
        },
      );
      return LabelModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteWorkspaceLabel(String workspaceId, String labelId) async {
    try {
      await dio.delete(ApiEndpoints.workspaceLabel(workspaceId, labelId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<LabelModel> addLabelToTask(String taskId, String labelId) async {
    try {
      final response = await dio.post(ApiEndpoints.taskLabel(taskId, labelId));
      return LabelModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> removeLabelFromTask(String taskId, String labelId) async {
    try {
      await dio.delete(ApiEndpoints.taskLabel(taskId, labelId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Failure _handleDioError(DioException e) {

    if (e.response != null && e.response?.data is Map) {
      final errorData = e.response!.data as Map<String, dynamic>;
      final err = errorData['error'];
      final message = err is Map ? err['message'] : err?.toString();
      return ServerFailure(
        message: message ?? 'Server error occurred',
        statusCode: e.response?.statusCode,
      );
    }
    return ServerFailure(
      message: e.message ?? 'Network connection error',
      statusCode: e.response?.statusCode,
    );
  }
}
