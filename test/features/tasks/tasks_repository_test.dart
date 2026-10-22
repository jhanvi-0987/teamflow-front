import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/features/tasks/domain/models/task_model.dart';
import 'package:mobile/features/tasks/domain/models/comment_model.dart';
import 'package:mobile/features/tasks/domain/repositories/tasks_repository.dart';

class MockTasksRepository implements TasksRepository {
  final List<TaskModel> _tasks = [];
  final List<CommentModel> _comments = [];

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
    final task = TaskModel(
      id: 'task-${_tasks.length + 1}',
      projectId: projectId,
      title: title,
      description: description,
      status: status ?? TaskStatus.todo,
      priority: priority ?? TaskPriority.medium,
      position: position ?? 0.0,
      version: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _tasks.add(task);
    return task;
  }

  @override
  Future<List<TaskModel>> listTasks(
    String projectId, {
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    String? search,
  }) async {
    return _tasks.where((t) {
      if (t.projectId != projectId) return false;
      if (status != null && t.status != status) return false;
      if (priority != null && t.priority != priority) return false;
      return true;
    }).toList();
  }

  @override
  Future<TaskModel> getTaskById(String taskId) async {
    return _tasks.firstWhere((t) => t.id == taskId);
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
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    final existing = _tasks[idx];

    // Optimistic Concurrency Control
    if (version != null && version != existing.version) {
      throw const ServerFailure(
        statusCode: 409,
        code: 'CONFLICT',
        message: 'Task was modified by another request',
      );
    }

    final updated = existing.copyWith(
      title: title ?? existing.title,
      description: description ?? existing.description,
      status: status ?? existing.status,
      priority: priority ?? existing.priority,
      version: existing.version + 1,
      updatedAt: DateTime.now(),
    );
    _tasks[idx] = updated;
    return updated;
  }

  @override
  Future<TaskModel> transitionStatus(
    String taskId,
    TaskStatus status, {
    double? position,
    int? version,
  }) async {
    return updateTask(
      taskId,
      status: status,
      position: position,
      version: version,
    );
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
  }

  @override
  Future<CommentModel> createComment(String taskId, String body) async {
    final comment = CommentModel(
      id: 'comment-${_comments.length + 1}',
      taskId: taskId,
      authorId: 'user-1',
      body: body,
      author: const UserSummary(
        id: 'user-1',
        name: 'Alice',
        email: 'alice@example.com',
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _comments.add(comment);

    // increment comment count on task
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(
        commentCount: _tasks[idx].commentCount + 1,
      );
    }

    return comment;
  }

  @override
  Future<List<CommentModel>> listComments(String taskId) async {
    return _comments.where((c) => c.taskId == taskId).toList();
  }

  @override
  Future<void> deleteComment(String commentId) async {
    _comments.removeWhere((c) => c.id == commentId);
  }
}

void main() {
  group('Tasks & Kanban Flow (Unit)', () {
    late MockTasksRepository repo;

    setUp(() {
      repo = MockTasksRepository();
    });

    test('createTask should create task with version 1', () async {
      final task = await repo.createTask(
        projectId: 'proj-1',
        title: 'Implement Auth Tokens',
        priority: TaskPriority.high,
      );

      expect(task.id, 'task-1');
      expect(task.version, 1);
      expect(task.status, TaskStatus.todo);
      expect(task.priority, TaskPriority.high);
    });

    test('transitionStatus should advance status and increment version atomically', () async {
      final task = await repo.createTask(
        projectId: 'proj-1',
        title: 'Build UI',
      );

      final inProgress = await repo.transitionStatus(
        task.id,
        TaskStatus.inProgress,
        version: task.version,
      );

      expect(inProgress.status, TaskStatus.inProgress);
      expect(inProgress.version, 2);
    });

    test('Optimistic Concurrency: should throw 409 Conflict when version mismatches', () async {
      final task = await repo.createTask(
        projectId: 'proj-1',
        title: 'Concurrent Task',
      );

      // Client A updates first -> version becomes 2
      await repo.transitionStatus(
        task.id,
        TaskStatus.inProgress,
        version: 1,
      );

      // Client B attempts to update with stale version 1
      expect(
        () => repo.transitionStatus(
          task.id,
          TaskStatus.done,
          version: 1, // stale!
        ),
        throwsA(
          isA<ServerFailure>().having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    });

    test('Comments: createComment should add comment and increment commentCount', () async {
      final task = await repo.createTask(
        projectId: 'proj-1',
        title: 'Commentable Task',
      );

      expect(task.commentCount, 0);

      final comment = await repo.createComment(task.id, 'Great progress team!');
      expect(comment.body, 'Great progress team!');

      final updatedTask = await repo.getTaskById(task.id);
      expect(updatedTask.commentCount, 1);

      final comments = await repo.listComments(task.id);
      expect(comments.length, 1);
      expect(comments.first.author.name, 'Alice');
    });
  });
}
