import '../../domain/models/project.dart';
import '../../domain/repositories/projects_repository.dart';
import '../datasources/projects_remote_data_source.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final ProjectsRemoteDataSource remoteDataSource;

  ProjectsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Project> createProject({
    required String workspaceId,
    required String name,
    required String key,
    String? description,
  }) {
    return remoteDataSource.createProject(
      workspaceId: workspaceId,
      name: name,
      key: key,
      description: description,
    );
  }

  @override
  Future<List<Project>> listProjects(String workspaceId, {bool includeArchived = false}) {
    return remoteDataSource.listProjects(workspaceId, includeArchived: includeArchived);
  }

  @override
  Future<Project> getProjectById(String projectId) {
    return remoteDataSource.getProjectById(projectId);
  }

  @override
  Future<Project> updateProject(
    String projectId, {
    String? name,
    String? description,
    String? status,
  }) {
    return remoteDataSource.updateProject(
      projectId,
      name: name,
      description: description,
      status: status,
    );
  }

  @override
  Future<void> archiveProject(String projectId) {
    return remoteDataSource.archiveProject(projectId);
  }
}
