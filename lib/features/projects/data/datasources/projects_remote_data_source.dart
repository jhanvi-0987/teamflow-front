import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/project.dart';

abstract class ProjectsRemoteDataSource {
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

class ProjectsRemoteDataSourceImpl implements ProjectsRemoteDataSource {
  final Dio dio;

  ProjectsRemoteDataSourceImpl({required this.dio});

  @override
  Future<Project> createProject({
    required String workspaceId,
    required String name,
    required String key,
    String? description,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.workspaceProjects(workspaceId),
        data: {
          'name': name,
          'key': key,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      return Project.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<Project>> listProjects(
    String workspaceId, {
    bool includeArchived = false,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.workspaceProjects(workspaceId),
        queryParameters: {
          if (includeArchived) 'includeArchived': 'true',
        },
      );
      final list = response.data as List<dynamic>;
      return list
          .map((item) => Project.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Project> getProjectById(String projectId) async {
    try {
      final response = await dio.get(ApiEndpoints.project(projectId));
      return Project.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Project> updateProject(
    String projectId, {
    String? name,
    String? description,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (status != null) data['status'] = status;

      final response = await dio.patch(
        ApiEndpoints.project(projectId),
        data: data,
      );
      return Project.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> archiveProject(String projectId) async {
    try {
      await dio.post(ApiEndpoints.projectArchive(projectId));
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
