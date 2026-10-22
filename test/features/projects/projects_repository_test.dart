import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/projects/domain/models/project.dart';
import 'package:mobile/features/projects/domain/repositories/projects_repository.dart';

class MockProjectsRepository implements ProjectsRepository {
  final List<Project> _projects = [];

  @override
  Future<Project> createProject({
    required String workspaceId,
    required String name,
    required String key,
    String? description,
  }) async {
    final proj = Project(
      id: 'proj-${_projects.length + 1}',
      workspaceId: workspaceId,
      name: name,
      key: key,
      description: description,
      status: 'ACTIVE',
      taskCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _projects.add(proj);
    return proj;
  }

  @override
  Future<List<Project>> listProjects(
    String workspaceId, {
    bool includeArchived = false,
  }) async {
    return _projects.where((p) {
      if (p.workspaceId != workspaceId) return false;
      if (!includeArchived && p.status == 'ARCHIVED') return false;
      return true;
    }).toList();
  }

  @override
  Future<Project> getProjectById(String projectId) async {
    return _projects.firstWhere((p) => p.id == projectId);
  }

  @override
  Future<Project> updateProject(
    String projectId, {
    String? name,
    String? description,
    String? status,
  }) async {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    final existing = _projects[idx];
    final updated = existing.copyWith(
      name: name ?? existing.name,
      description: description ?? existing.description,
      status: status ?? existing.status,
    );
    _projects[idx] = updated;
    return updated;
  }

  @override
  Future<void> archiveProject(String projectId) async {
    await updateProject(projectId, status: 'ARCHIVED');
  }
}

void main() {
  group('Projects Flow (Unit)', () {
    late MockProjectsRepository repo;

    setUp(() {
      repo = MockProjectsRepository();
    });

    test('createProject should store project scoped to workspace', () async {
      final p1 = await repo.createProject(
        workspaceId: 'ws-1',
        name: 'Alpha Project',
        key: 'ALPHA',
      );

      expect(p1.id, 'proj-1');
      expect(p1.key, 'ALPHA');
      expect(p1.workspaceId, 'ws-1');

      final listWs1 = await repo.listProjects('ws-1');
      expect(listWs1.length, 1);

      // Isolation check: another workspace has 0 projects
      final listWs2 = await repo.listProjects('ws-2');
      expect(listWs2.isEmpty, true);
    });

    test('updateProject and archiveProject should update status', () async {
      final p = await repo.createProject(
        workspaceId: 'ws-1',
        name: 'Beta Project',
        key: 'BETA',
      );

      final updated = await repo.updateProject(
        p.id,
        name: 'Beta Project Renamed',
      );
      expect(updated.name, 'Beta Project Renamed');

      await repo.archiveProject(p.id);
      final activeList = await repo.listProjects('ws-1');
      expect(activeList.isEmpty, true);

      final allList = await repo.listProjects('ws-1', includeArchived: true);
      expect(allList.length, 1);
      expect(allList.first.status, 'ARCHIVED');
    });
  });
}
