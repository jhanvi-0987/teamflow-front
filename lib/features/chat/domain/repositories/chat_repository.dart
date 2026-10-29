import '../models/channel_model.dart';
import '../models/message_model.dart';
import '../models/reaction_model.dart';

abstract class ChatRepository {
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
