import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/tasks_remote_data_source.dart';
import '../../data/repositories/tasks_repository_impl.dart';
import '../../domain/models/task_model.dart';
import '../../domain/models/comment_model.dart';
import '../../domain/repositories/tasks_repository.dart';

final tasksRemoteDataSourceProvider = Provider<TasksRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TasksRemoteDataSourceImpl(dio: apiClient.dio);
});

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final remote = ref.watch(tasksRemoteDataSourceProvider);
  return TasksRepositoryImpl(remoteDataSource: remote);
});

final projectTasksProvider =
    FutureProvider.family<List<TaskModel>, String>((ref, projectId) async {
  final repo = ref.watch(tasksRepositoryProvider);
  return repo.listTasks(projectId);
});

final taskDetailProvider =
    FutureProvider.family<TaskModel, String>((ref, taskId) async {
  final repo = ref.watch(tasksRepositoryProvider);
  return repo.getTaskById(taskId);
});

final taskCommentsProvider =
    FutureProvider.family<List<CommentModel>, String>((ref, taskId) async {
  final repo = ref.watch(tasksRepositoryProvider);
  return repo.listComments(taskId);
});

final userSearchProvider =
    FutureProvider.family<List<UserSummary>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(tasksRepositoryProvider);
  return repo.searchUsers(query);
});

