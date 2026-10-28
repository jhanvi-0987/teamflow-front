
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/models/channel_model.dart';
import '../../domain/models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_notification_providers.dart';

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
  final Ref _ref;
  StreamSubscription? _messageSub;
  StreamSubscription? _deliveredSub;
  StreamSubscription? _readSub;

  ChannelMessagesNotifier({
    required ChatRepository repository,
    required SocketService socketService,
    required String channelId,
    required Ref ref,
  })  : _repository = repository,
        _socketService = socketService,
        _channelId = channelId,
        _ref = ref,
        super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    loadMessages();
    _socketService.connect();
    _socketService.joinChannel(_channelId);

    _messageSub = _socketService.onChatMessage.listen((data) {
      if (!mounted) return;
      if (data['channelId'] == _channelId && data['message'] != null) {
        final newMsg =
            MessageModel.fromJson(Map<String, dynamic>.from(data['message']));
        if (state.value != null) {
          final current = state.value!;
          if (!current.any((m) => m.id == newMsg.id)) {
            state = AsyncValue.data([...current, newMsg]);
          }
        }
        final activeChannelId = _ref.read(activeChatChannelProvider);
        final currentUserId = _ref.read(authControllerProvider).user?.id;
        if (activeChannelId == _channelId &&
            currentUserId != null &&
            newMsg.senderId != currentUserId) {
          _repository.markAsRead(_channelId).catchError((_) {});
        }
      }
    });

    _deliveredSub = _socketService.onMessagesDelivered.listen((data) {
      if (!mounted) return;
      if (state.value == null) return;
      if (data['channelId'] == _channelId) {
        final rawList = data['messageIds'] as List?;
        final idsSet = rawList != null && rawList.isNotEmpty
            ? rawList.map((e) => e.toString()).toSet()
            : null;
        final current = state.value!;
        final updated = current.map((m) {
          final matches = idsSet == null || idsSet.contains(m.id);
          if (matches && m.status.toLowerCase() == 'sent') {
            return m.copyWith(status: 'delivered', deliveredAt: DateTime.now());
          }
          return m;
        }).toList();
        state = AsyncValue.data(updated);
      }
    });

    _readSub = _socketService.onMessagesRead.listen((data) {
      if (!mounted) return;
      if (state.value == null) return;
      if (data['channelId'] == _channelId) {
        final rawList = data['messageIds'] as List?;
        final idsSet = rawList != null && rawList.isNotEmpty
            ? rawList.map((e) => e.toString()).toSet()
            : null;
        final readerId = data['readerId'] as String?;
        final current = state.value!;
        final updated = current.map((m) {
          final matches = idsSet != null
              ? idsSet.contains(m.id)
              : (readerId == null || m.senderId != readerId);
          if (matches && m.status.toLowerCase() != 'read') {
            return m.copyWith(status: 'read', readAt: DateTime.now());
          }
          return m;
        }).toList();
        state = AsyncValue.data(updated);
      }
    });
  }

  Future<void> loadMessages() async {
    try {
      final messages = await _repository.getMessages(_channelId);
      if (!mounted) return;
      state = AsyncValue.data(messages);
      _repository.markAsRead(_channelId).catchError((_) {});
    } catch (e, st) {
      if (!mounted) return;
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
      if (!mounted) return true;
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
    _deliveredSub?.cancel();
    _readSub?.cancel();
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
      ref: ref,
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

/// Provider for fetching full channel/DM details including members and roles
final channelDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, channelId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getChannelDetails(channelId);
});
