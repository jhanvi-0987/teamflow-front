import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/channel_model.dart';
import '../../domain/models/message_model.dart';
import '../../domain/models/reaction_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChannelModel>> getChannels(String workspaceId);

  Future<ChannelModel> createChannel(
    String workspaceId, {
    required String name,
    String? topic,
    ChannelType type = ChannelType.public,
  });

  Future<ChannelModel> getOrCreateDM(String workspaceId, String targetUserId);

  Future<List<MessageModel>> getMessages(String channelId, {int limit = 50});

  Future<MessageModel> sendMessage(
    String channelId, {
    required String content,
    String? taskId,
    String? replyToId,
  });

  Future<void> markAsRead(String channelId);

  Future<Map<String, dynamic>> getChannelDetails(String channelId);

  Future<List<ReactionGroupModel>> toggleReaction(
    String channelId,
    String messageId,
    String emoji,
  );

  Future<void> deleteMessage(String channelId, String messageId);

  Future<Map<String, dynamic>> togglePinMessage(String channelId, String messageId);

  Future<MessageModel> forwardMessage(
    String channelId,
    String messageId,
    String targetChannelId,
  );
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio dio;

  ChatRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ChannelModel>> getChannels(String workspaceId) async {
    try {
      final response = await dio.get(
        ApiEndpoints.workspaceChannels(workspaceId),
      );
      final list = response.data as List<dynamic>;
      return list
          .map((item) => ChannelModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ChannelModel> createChannel(
    String workspaceId, {
    required String name,
    String? topic,
    ChannelType type = ChannelType.public,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.workspaceChannels(workspaceId),
        data: {
          'name': name.trim(),
          if (topic != null && topic.isNotEmpty) 'topic': topic.trim(),
          'type': type.toApiString(),
        },
      );
      return ChannelModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ChannelModel> getOrCreateDM(String workspaceId, String targetUserId) async {
    try {
      final response = await dio.post(
        ApiEndpoints.workspaceDirectMessages(workspaceId),
        data: {'targetUserId': targetUserId},
      );
      return ChannelModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String channelId, {int limit = 50}) async {
    try {
      final response = await dio.get(
        ApiEndpoints.channelMessages(channelId, limit: limit),
      );
      final list = response.data as List<dynamic>;
      return list
          .map((item) => MessageModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<MessageModel> sendMessage(
    String channelId, {
    required String content,
    String? taskId,
    String? replyToId,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.channelSendMessage(channelId),
        data: {
          'content': content.trim(),
          if (taskId != null && taskId.isNotEmpty) 'taskId': taskId,
          if (replyToId != null && replyToId.isNotEmpty) 'replyToId': replyToId,
        },
      );
      return MessageModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> markAsRead(String channelId) async {
    try {
      await dio.post(ApiEndpoints.channelRead(channelId));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getChannelDetails(String channelId) async {
    try {
      final response = await dio.get(ApiEndpoints.channelDetails(channelId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<ReactionGroupModel>> toggleReaction(
    String channelId,
    String messageId,
    String emoji,
  ) async {
    try {
      final response = await dio.post(
        ApiEndpoints.messageReactions(channelId, messageId),
        data: {'emoji': emoji},
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['reactions'] as List<dynamic>? ?? [];
      return list
          .map((item) => ReactionGroupModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteMessage(String channelId, String messageId) async {
    try {
      await dio.delete(ApiEndpoints.message(channelId, messageId));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> togglePinMessage(
    String channelId,
    String messageId,
  ) async {
    try {
      final response = await dio.patch(
        ApiEndpoints.messagePin(channelId, messageId),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<MessageModel> forwardMessage(
    String channelId,
    String messageId,
    String targetChannelId,
  ) async {
    try {
      final response = await dio.post(
        ApiEndpoints.messageForward(channelId, messageId),
        data: {'targetChannelId': targetChannelId},
      );
      return MessageModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Failure _handleError(DioException error) {
    if (error.response?.data != null && error.response!.data is Map) {
      final data = error.response!.data as Map<String, dynamic>;
      final err = data['error'] as Map<String, dynamic>?;
      if (err != null) {
        return ServerFailure(
          message: err['message']?.toString() ?? 'Failed to execute chat operation',
          statusCode: error.response?.statusCode,
        );
      }
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }
    return ServerFailure(
      message: error.message ?? 'Unknown chat error',
      statusCode: error.response?.statusCode,
    );
  }
}
