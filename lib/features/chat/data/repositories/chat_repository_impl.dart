import '../../domain/models/channel_model.dart';
import '../../domain/models/message_model.dart';
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
  }) =>
      _remoteDataSource.sendMessage(
        channelId,
        content: content,
        taskId: taskId,
      );

  @override
  Future<void> markAsRead(String channelId) =>
      _remoteDataSource.markAsRead(channelId);
}
