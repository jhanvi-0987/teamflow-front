import '../models/channel_model.dart';
import '../models/message_attachment_model.dart';
import '../models/message_model.dart';
import '../models/reaction_model.dart';
import '../models/call_session_model.dart';

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

  Future<MessageAttachmentModel> uploadAttachment(
    String channelId,
    String filePath, {
    void Function(int sent, int total)? onProgress,
  });

  Future<MessageModel> sendMessage(
    String channelId, {
    String? content,
    String? taskId,
    String? replyToId,
    List<MessageAttachmentModel>? attachments,
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

  Future<CallSessionModel> initiateCall(
    String channelId,
    CallType type, {
    String? targetUserId,
  });

  Future<CallSessionModel> acceptCall(String callId);

  Future<CallSessionModel> rejectCall(String callId, {String? reason});

  Future<CallSessionModel> endCall(String callId);

  Future<List<CallSessionModel>> getCallHistory(
    String channelId, {
    int limit = 20,
  });
}
