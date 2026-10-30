import '../../domain/models/channel_model.dart';
import '../../domain/models/message_model.dart';
import '../../domain/models/reaction_model.dart';
import '../../domain/models/call_session_model.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl({required ChatRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<ChannelModel>> getChannels(String workspaceId) =>
      _remoteDataSource.getChannels(workspaceId);

  @override
  Future<ChannelModel> createChannel(
    String workspaceId, {
    required String name,
    String? topic,
    ChannelType type = ChannelType.public,
  }) =>
      _remoteDataSource.createChannel(
        workspaceId,
        name: name,
        topic: topic,
        type: type,
      );

  @override
  Future<ChannelModel> getOrCreateDM(String workspaceId, String targetUserId) =>
      _remoteDataSource.getOrCreateDM(workspaceId, targetUserId);

  @override
  Future<List<MessageModel>> getMessages(String channelId, {int limit = 50}) =>
      _remoteDataSource.getMessages(channelId, limit: limit);

  @override
  Future<MessageModel> sendMessage(
    String channelId, {
    required String content,
    String? taskId,
    String? replyToId,
  }) =>
      _remoteDataSource.sendMessage(
        channelId,
        content: content,
        taskId: taskId,
        replyToId: replyToId,
      );

  @override
  Future<void> markAsRead(String channelId) =>
      _remoteDataSource.markAsRead(channelId);

  @override
  Future<Map<String, dynamic>> getChannelDetails(String channelId) =>
      _remoteDataSource.getChannelDetails(channelId);

  @override
  Future<List<ReactionGroupModel>> toggleReaction(
    String channelId,
    String messageId,
    String emoji,
  ) =>
      _remoteDataSource.toggleReaction(channelId, messageId, emoji);

  @override
  Future<void> deleteMessage(String channelId, String messageId) =>
      _remoteDataSource.deleteMessage(channelId, messageId);

  @override
  Future<Map<String, dynamic>> togglePinMessage(
    String channelId,
    String messageId,
  ) =>
      _remoteDataSource.togglePinMessage(channelId, messageId);

  @override
  Future<MessageModel> forwardMessage(
    String channelId,
    String messageId,
    String targetChannelId,
  ) =>
      _remoteDataSource.forwardMessage(channelId, messageId, targetChannelId);

  @override
  Future<CallSessionModel> initiateCall(
    String channelId,
    CallType type, {
    String? targetUserId,
  }) =>
      _remoteDataSource.initiateCall(
        channelId,
        type,
        targetUserId: targetUserId,
      );

  @override
  Future<CallSessionModel> acceptCall(String callId) =>
      _remoteDataSource.acceptCall(callId);

  @override
  Future<CallSessionModel> rejectCall(String callId, {String? reason}) =>
      _remoteDataSource.rejectCall(callId, reason: reason);

  @override
  Future<CallSessionModel> endCall(String callId) =>
      _remoteDataSource.endCall(callId);

  @override
  Future<List<CallSessionModel>> getCallHistory(
    String channelId, {
    int limit = 20,
  }) =>
      _remoteDataSource.getCallHistory(channelId, limit: limit);
}
