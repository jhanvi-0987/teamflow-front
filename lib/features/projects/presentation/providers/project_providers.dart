import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/projects_remote_data_source.dart';
import '../../data/repositories/projects_repository_impl.dart';
import '../../domain/models/project.dart';
import '../../domain/repositories/projects_repository.dart';

final projectsRemoteDataSourceProvider =
    Provider<ProjectsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProjectsRemoteDataSourceImpl(dio: apiClient.dio);
});

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  final remote = ref.watch(projectsRemoteDataSourceProvider);
  return ProjectsRepositoryImpl(remoteDataSource: remote);
});

final workspaceProjectsProvider =
    FutureProvider.family<List<Project>, String>((ref, workspaceId) async {
  final repo = ref.watch(projectsRepositoryProvider);
  return repo.listProjects(workspaceId);
});

final projectDetailProvider =
    FutureProvider.family<Project, String>((ref, projectId) async {
  final repo = ref.watch(projectsRepositoryProvider);
  return repo.getProjectById(projectId);
});
