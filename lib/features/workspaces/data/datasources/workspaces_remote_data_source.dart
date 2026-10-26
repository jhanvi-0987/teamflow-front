import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/workspace.dart';
import '../../domain/models/workspace_member.dart';
import '../../domain/models/invitation.dart';

abstract class WorkspacesRemoteDataSource {
  Future<Workspace> createWorkspace({required String name, String? slug});
  Future<List<Workspace>> getUserWorkspaces();
  Future<Workspace> getWorkspaceById(String id);
  Future<Workspace> updateWorkspace(String id, {String? name, String? slug});
  Future<void> archiveWorkspace(String id);
  Future<void> transferOwnership(String workspaceId, String newOwnerId);
  Future<void> leaveWorkspace(String workspaceId);

  // Members
  Future<List<WorkspaceMember>> getMembers(String workspaceId, {String? query});
  Future<WorkspaceMember> updateMemberRole(
    String workspaceId,
    String userId,
    WorkspaceRole role,
  );
  Future<void> removeMember(String workspaceId, String userId);

  // Invitations
  Future<Invitation> inviteMember(
    String workspaceId,
    String email,
    WorkspaceRole role,
  );
  Future<List<Invitation>> getPendingInvitations(String workspaceId);
  Future<void> revokeInvitation(String workspaceId, String invitationId);
  Future<Workspace> acceptInvitation(String token);
  Future<void> declineInvitation(String token);
  Future<Invitation> previewInvitation(String token);
}

class WorkspacesRemoteDataSourceImpl implements WorkspacesRemoteDataSource {
  final Dio dio;

  WorkspacesRemoteDataSourceImpl(this.dio);

  @override
  Future<Workspace> createWorkspace({required String name, String? slug}) async {
    try {
      final data = <String, dynamic>{'name': name.trim()};
      if (slug != null && slug.trim().isNotEmpty) {
        data['slug'] = slug.trim();
      }
      final response = await dio.post(ApiEndpoints.workspaces, data: data);
      return Workspace.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<Workspace>> getUserWorkspaces() async {
    try {
      final response = await dio.get(ApiEndpoints.workspaces);
      final list = response.data as List<dynamic>;
      return list
          .map((item) => Workspace.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Workspace> getWorkspaceById(String id) async {
    try {
      final response = await dio.get(ApiEndpoints.workspace(id));
      return Workspace.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Workspace> updateWorkspace(String id, {String? name, String? slug}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        data['name'] = name.trim();
      }
      if (slug != null && slug.trim().isNotEmpty) {
        data['slug'] = slug.trim();
      }
      final response = await dio.patch(ApiEndpoints.workspace(id), data: data);
      return Workspace.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> archiveWorkspace(String id) async {
    try {
      await dio.post(ApiEndpoints.workspaceArchive(id));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> transferOwnership(String workspaceId, String newOwnerId) async {
    try {
      await dio.post(
        ApiEndpoints.workspaceTransferOwnership(workspaceId),
        data: {'newOwnerId': newOwnerId},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> leaveWorkspace(String workspaceId) async {
    try {
      await dio.post(ApiEndpoints.workspaceLeave(workspaceId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<WorkspaceMember>> getMembers(String workspaceId, {String? query}) async {
    try {
      final response = await dio.get(
        ApiEndpoints.workspaceMembers(workspaceId, query: query),
      );
      final list = response.data as List<dynamic>;
      return list
          .map((item) => WorkspaceMember.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<WorkspaceMember> updateMemberRole(
    String workspaceId,
    String userId,
    WorkspaceRole role,
  ) async {
    try {
      final response = await dio.patch(
        ApiEndpoints.workspaceMember(workspaceId, userId),
        data: {'role': role.toApiString()},
      );
      return WorkspaceMember.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> removeMember(String workspaceId, String userId) async {
    try {
      await dio.delete(ApiEndpoints.workspaceMember(workspaceId, userId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Invitation> inviteMember(
    String workspaceId,
    String email,
    WorkspaceRole role,
  ) async {
    try {
      final response = await dio.post(
        ApiEndpoints.workspaceInvitations(workspaceId),
        data: {
          'email': email.trim().toLowerCase(),
          'role': role.toApiString(),
        },
      );
      return Invitation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<Invitation>> getPendingInvitations(String workspaceId) async {
    try {
      final response = await dio.get(ApiEndpoints.workspaceInvitations(workspaceId));
      final list = response.data as List<dynamic>;
      return list
          .map((item) => Invitation.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> revokeInvitation(String workspaceId, String invitationId) async {
    try {
      await dio.delete(
        ApiEndpoints.workspaceInvitation(workspaceId, invitationId),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Workspace> acceptInvitation(String token) async {
    try {
      final response = await dio.post(
        ApiEndpoints.invitationsAccept,
        data: {'token': token.trim()},
      );
      final data = response.data as Map<String, dynamic>;
      final workspaceMap = data['workspace'] as Map<String, dynamic>;
      workspaceMap['role'] = data['role'];
      return Workspace.fromJson(workspaceMap);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> declineInvitation(String token) async {
    try {
      await dio.post(
        ApiEndpoints.invitationsDecline,
        data: {'token': token.trim()},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Invitation> previewInvitation(String token) async {
    try {
      final response = await dio.post(
        ApiEndpoints.invitationsPreviewPost,
        data: {'token': token.trim()},
      );
      return Invitation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Failure _handleDioError(DioException error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final data = error.response!.data as Map<String, dynamic>;
      final errObj = data['error'] as Map<String, dynamic>?;
      if (errObj != null) {
        return WorkspaceFailure(
          message: errObj['message']?.toString() ?? 'Workspace error',
          code: errObj['code']?.toString(),
        );
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    return ServerFailure(
      message: error.message ?? 'Server error occurred',
      statusCode: error.response?.statusCode,
    );
  }
}
