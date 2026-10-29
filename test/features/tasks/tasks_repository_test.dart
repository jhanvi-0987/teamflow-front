import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/features/tasks/domain/models/task_model.dart';
import 'package:mobile/features/tasks/domain/models/comment_model.dart';
import 'package:mobile/features/tasks/domain/models/subtask_model.dart';
import 'package:mobile/features/tasks/domain/models/label_model.dart';
import 'package:mobile/features/tasks/domain/repositories/tasks_repository.dart';

class MockTasksRepository implements TasksRepository {
  final List<TaskModel> _tasks = [];
  final List<CommentModel> _comments = [];
  final List<SubtaskModel> _subtasks = [];
  final List<LabelModel> _labels = [];

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

  @override
  Future<List<UserSummary>> searchUsers(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final allUsers = [
      const UserSummary(id: 'user-1', name: 'Alice', email: 'alice@example.com'),
      const UserSummary(id: 'user-2', name: 'Solo External', email: 'solo@example.com'),
    ];

    return allUsers.where((u) {
      return u.email.toLowerCase().contains(clean) ||
          u.name.toLowerCase().contains(clean);
    }).toList();
  }

  // --- SUBTASKS ---

  @override
  Future<SubtaskModel> createSubtask(String taskId, String title, {double? position}) async {
    final sub = SubtaskModel(
      id: 'sub-${_subtasks.length + 1}',
      taskId: taskId,
      title: title,
      position: position ?? 0.0,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
    _subtasks.add(sub);
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(
        subtasks: [..._tasks[idx].subtasks, sub],
      );
    }
    return sub;
  }

  @override
  Future<SubtaskModel> updateSubtask(
    String taskId,
    String subtaskId, {
    String? title,
    bool? isCompleted,
    double? position,
  }) async {
    final idx = _subtasks.indexWhere((s) => s.id == subtaskId);
    final existing = _subtasks[idx];
    final updated = existing.copyWith(
      title: title ?? existing.title,
      isCompleted: isCompleted ?? existing.isCompleted,
      position: position ?? existing.position,
    );
    _subtasks[idx] = updated;

    final taskIdx = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIdx != -1) {
      final taskSubs = _tasks[taskIdx]
          .subtasks
          .map((s) => s.id == subtaskId ? updated : s)
          .toList();
      _tasks[taskIdx] = _tasks[taskIdx].copyWith(subtasks: taskSubs);
    }
    return updated;
  }

  @override
  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    _subtasks.removeWhere((s) => s.id == subtaskId);
    final taskIdx = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIdx != -1) {
      final taskSubs = _tasks[taskIdx]
          .subtasks
          .where((s) => s.id != subtaskId)
          .toList();
      _tasks[taskIdx] = _tasks[taskIdx].copyWith(subtasks: taskSubs);
    }
  }

  // --- LABELS ---

  @override
  Future<List<LabelModel>> listWorkspaceLabels(String workspaceId) async {
    return _labels.where((l) => l.workspaceId == workspaceId).toList();
  }

  @override
  Future<LabelModel> createWorkspaceLabel(
    String workspaceId,
    String name,
    String colorHex,
  ) async {
    final label = LabelModel(
      id: 'lbl-${_labels.length + 1}',
      workspaceId: workspaceId,
      name: name,
      colorHex: colorHex,
    );
    _labels.add(label);
    return label;
  }

  @override
  Future<void> deleteWorkspaceLabel(String workspaceId, String labelId) async {
    _labels.removeWhere((l) => l.id == labelId);
  }

  @override
  Future<LabelModel> addLabelToTask(String taskId, String labelId) async {
    final label = _labels.firstWhere((l) => l.id == labelId);
    final taskIdx = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIdx != -1 && !_tasks[taskIdx].labels.any((l) => l.id == labelId)) {
      _tasks[taskIdx] = _tasks[taskIdx].copyWith(
        labels: [..._tasks[taskIdx].labels, label],
      );
    }
    return label;
  }

  @override
  Future<void> removeLabelFromTask(String taskId, String labelId) async {
    final taskIdx = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIdx != -1) {
      _tasks[taskIdx] = _tasks[taskIdx].copyWith(
        labels: _tasks[taskIdx].labels.where((l) => l.id != labelId).toList(),
      );
    }
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

    test('User Search: searchUsers should filter users across platform by email', () async {
      final results = await repo.searchUsers('solo');
      expect(results.length, 1);
      expect(results.first.email, 'solo@example.com');
      expect(results.first.name, 'Solo External');

      final empty = await repo.searchUsers('nonexistent@example.com');
      expect(empty.isEmpty, true);
    });

    test('Subtasks: create, toggle, progress and delete subtasks', () async {
      final task = await repo.createTask(
        projectId: 'proj-1',
        title: 'Checklist Task',
      );

      expect(task.totalSubtasks, 0);
      expect(task.hasSubtasks, false);

      final sub1 = await repo.createSubtask(task.id, 'Write unit tests');
      final sub2 = await repo.createSubtask(task.id, 'Implement UI');

      final taskWithSubs = await repo.getTaskById(task.id);
      expect(taskWithSubs.totalSubtasks, 2);
      expect(taskWithSubs.completedSubtasks, 0);
      expect(taskWithSubs.subtaskProgress, 0.0);

      // Toggle first subtask as complete
      await repo.updateSubtask(task.id, sub1.id, isCompleted: true);
      final taskUpdated = await repo.getTaskById(task.id);
      expect(taskUpdated.completedSubtasks, 1);
      expect(taskUpdated.subtaskProgress, 0.5);

      // Delete second subtask
      await repo.deleteSubtask(task.id, sub2.id);
      final taskAfterDelete = await repo.getTaskById(task.id);
      expect(taskAfterDelete.totalSubtasks, 1);
      expect(taskAfterDelete.completedSubtasks, 1);
      expect(taskAfterDelete.subtaskProgress, 1.0);
    });

    test('Labels: create workspace label, attach and detach from task', () async {
      final task = await repo.createTask(
        projectId: 'proj-1',
        title: 'Tagged Task',
      );

      final label = await repo.createWorkspaceLabel('ws-1', 'Frontend', '#2563EB');
      expect(label.name, 'Frontend');
      expect(label.colorHex, '#2563EB');

      await repo.addLabelToTask(task.id, label.id);
      final taskWithLabel = await repo.getTaskById(task.id);
      expect(taskWithLabel.labels.length, 1);
      expect(taskWithLabel.labels.first.name, 'Frontend');

      await repo.removeLabelFromTask(task.id, label.id);
      final taskWithoutLabel = await repo.getTaskById(task.id);
      expect(taskWithoutLabel.labels.isEmpty, true);
    });
  });
}

