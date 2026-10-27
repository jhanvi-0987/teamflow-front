import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/models/channel_model.dart';
import '../../domain/models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRemoteDataSourceImpl(dio: apiClient.dio);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remoteDataSource = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Auto-refreshing list of channels for the active workspace
final workspaceChannelsProvider =
    FutureProvider.family<List<ChannelModel>, String>((ref, workspaceId) async {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChannels(workspaceId);
});

/// State of messages for a single channel with real-time socket updates
class ChannelMessagesNotifier
    extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final ChatRepository _repository;
  final SocketService _socketService;
  final String _channelId;
  StreamSubscription? _messageSub;

  ChannelMessagesNotifier({
    required ChatRepository repository,
    required SocketService socketService,
    required String channelId,
  })  : _repository = repository,
        _socketService = socketService,
        _channelId = channelId,
        super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    loadMessages();
    _socketService.connect();
    _socketService.joinChannel(_channelId);

    _messageSub = _socketService.onChatMessage.listen((data) {
      if (data['channelId'] == _channelId && data['message'] != null) {
        final newMsg =
            MessageModel.fromJson(Map<String, dynamic>.from(data['message']));
        final current = state.value ?? [];
        if (!current.any((m) => m.id == newMsg.id)) {
          state = AsyncValue.data([...current, newMsg]);
        }
      }
    });
  }

  Future<void> loadMessages() async {
    try {
      final messages = await _repository.getMessages(_channelId);
      state = AsyncValue.data(messages);
      _repository.markAsRead(_channelId).catchError((_) {});
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> sendMessage(String content, {String? taskId}) async {
    if (content.trim().isEmpty) return false;
    try {
      final created = await _repository.sendMessage(
        _channelId,
        content: content,
        taskId: taskId,
      );
      final current = state.value ?? [];
      if (!current.any((m) => m.id == created.id)) {
        state = AsyncValue.data([...current, created]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  void setTyping(bool isTyping) {
    _socketService.sendTyping(_channelId, isTyping);
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _socketService.leaveChannel(_channelId);
    super.dispose();
  }
}

final channelMessagesProvider = StateNotifierProvider.family<
    ChannelMessagesNotifier, AsyncValue<List<MessageModel>>, String>(
  (ref, channelId) {
    final repo = ref.watch(chatRepositoryProvider);
    final socket = ref.watch(socketServiceProvider);
    return ChannelMessagesNotifier(
      repository: repo,
      socketService: socket,
      channelId: channelId,
    );
  },
);

/// Provider tracking who is currently typing in a channel
final channelTypingProvider =
    StreamProvider.family<String?, String>((ref, channelId) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.onUserTyping
      .where((event) => event['channelId'] == channelId)
      .map((event) {
    final isTyping = event['isTyping'] as bool? ?? false;
    if (isTyping) {
      return (event['email'] as String? ?? 'Someone').split('@').first;
    }
    return null;
  });
});
