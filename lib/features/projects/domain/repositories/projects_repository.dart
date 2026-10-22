import '../models/project.dart';

abstract class ProjectsRepository {
  Future<Project> createProject({
    required String workspaceId,
    required String name,
    required String key,
    String? description,
  });

  Future<List<Project>> listProjects(String workspaceId, {bool includeArchived = false});

  Future<Project> getProjectById(String projectId);

  Future<Project> updateProject(
    String projectId, {
    String? name,
    String? description,
    String? status,
  });

  Future<void> archiveProject(String projectId);
}
