import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../auth/token_storage.dart';
import '../network/api_endpoints.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';

class SocketService {
  final TokenStorage _tokenStorage;
  final String _socketUrl;
  socket_io.Socket? _socket;

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final _taskCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _taskUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _taskStatusChangedController = StreamController<Map<String, dynamic>>.broadcast();
  final _taskDeletedController = StreamController<Map<String, dynamic>>.broadcast();
  final _commentCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _subtaskCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _subtaskUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _subtaskDeletedController = StreamController<Map<String, dynamic>>.broadcast();
  final _taskLabelAddedController = StreamController<Map<String, dynamic>>.broadcast();
  final _taskLabelRemovedController = StreamController<Map<String, dynamic>>.broadcast();
  final _securityRevokedController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatReactionUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatMessageDeletedController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatMessagePinnedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callIncomingController = StreamController<Map<String, dynamic>>.broadcast();
  final _callAcceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callRejectedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callEndedController = StreamController<Map<String, dynamic>>.broadcast();
  final _callSignalController = StreamController<Map<String, dynamic>>.broadcast();
  final _userTypingController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageNotificationController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesDeliveredController = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesReadController = StreamController<Map<String, dynamic>>.broadcast();
  final Set<String> _activeChannels = {};

  Stream<Map<String, dynamic>> get onTaskCreated => _taskCreatedController.stream;
  Stream<Map<String, dynamic>> get onTaskUpdated => _taskUpdatedController.stream;
  Stream<Map<String, dynamic>> get onTaskStatusChanged => _taskStatusChangedController.stream;
  Stream<Map<String, dynamic>> get onTaskDeleted => _taskDeletedController.stream;
  Stream<Map<String, dynamic>> get onCommentCreated => _commentCreatedController.stream;
  Stream<Map<String, dynamic>> get onSubtaskCreated => _subtaskCreatedController.stream;
  Stream<Map<String, dynamic>> get onSubtaskUpdated => _subtaskUpdatedController.stream;
  Stream<Map<String, dynamic>> get onSubtaskDeleted => _subtaskDeletedController.stream;
  Stream<Map<String, dynamic>> get onTaskLabelAdded => _taskLabelAddedController.stream;
  Stream<Map<String, dynamic>> get onTaskLabelRemoved => _taskLabelRemovedController.stream;
  Stream<Map<String, dynamic>> get onSecurityRevoked => _securityRevokedController.stream;
  Stream<Map<String, dynamic>> get onChatMessage => _chatMessageController.stream;
  Stream<Map<String, dynamic>> get onChatReactionUpdated => _chatReactionUpdatedController.stream;
  Stream<Map<String, dynamic>> get onChatMessageDeleted => _chatMessageDeletedController.stream;
  Stream<Map<String, dynamic>> get onChatMessagePinned => _chatMessagePinnedController.stream;
  Stream<Map<String, dynamic>> get onCallIncoming => _callIncomingController.stream;
  Stream<Map<String, dynamic>> get onCallAccepted => _callAcceptedController.stream;
  Stream<Map<String, dynamic>> get onCallRejected => _callRejectedController.stream;
  Stream<Map<String, dynamic>> get onCallEnded => _callEndedController.stream;
  Stream<Map<String, dynamic>> get onCallSignal => _callSignalController.stream;
  Stream<Map<String, dynamic>> get onUserTyping => _userTypingController.stream;
  Stream<Map<String, dynamic>> get onMessageNotification => _messageNotificationController.stream;
  Stream<Map<String, dynamic>> get onNotificationCreated => _notificationCreatedController.stream;
  Stream<Map<String, dynamic>> get onMessagesDelivered => _messagesDeliveredController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _messagesReadController.stream;

  SocketService({
    required TokenStorage tokenStorage,
    String? socketUrl,
  })  : _tokenStorage = tokenStorage,
        _socketUrl = socketUrl ?? _deriveSocketUrl(ApiEndpoints.baseUrl);

  static String _deriveSocketUrl(String apiBaseUrl) {
    final uri = Uri.parse(apiBaseUrl);
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portPart';
  }

  Future<void> connect() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      debugPrint('[SocketService] No access token available, skipping connect');
      return;
    }

    if (_socket != null && _socket!.connected) {
      return;
    }

    _socket?.dispose();

    final options = socket_io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .disableAutoConnect()
        .setAuth({'token': token})
        .enableReconnection()
        .setReconnectionDelay(1000)
        .setReconnectionAttempts(10)
        .build();

    debugPrint('[SocketService] Connecting to $_socketUrl with auth token...');
    _socket = socket_io.io(_socketUrl, options);

    _socket!.onConnect((_) {
      debugPrint('[SocketService] Connected to $_socketUrl (Socket ID: ${_socket?.id})');
      _isConnected = true;
      _connectionStateController.add(true);
      for (final channelId in _activeChannels) {
        _socket!.emit('join:channel', {'channelId': channelId});
        debugPrint('[SocketService] Re-joined active channel room on connect: $channelId');
      }
    });

    _socket!.onDisconnect((reason) {
      debugPrint('[SocketService] Disconnected from $_socketUrl, reason: $reason');
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onConnectError((err) {
      debugPrint('[SocketService] Connection error to $_socketUrl: $err');
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onError((err) {
      debugPrint('[SocketService] Socket error: $err');
    });

    // Listen to real-time events from server
    _socket!.on('task:created', (data) {
      if (data is Map) {
        _taskCreatedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('task:updated', (data) {
      if (data is Map) {
        _taskUpdatedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('task:status_changed', (data) {
      if (data is Map) {
        _taskStatusChangedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('task:deleted', (data) {
      if (data is Map) {
        _taskDeletedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('comment:created', (data) {
      if (data is Map) {
        _commentCreatedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('subtask:created', (data) {
      if (data is Map) {
        _subtaskCreatedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('subtask:updated', (data) {
      if (data is Map) {
        _subtaskUpdatedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('subtask:deleted', (data) {
      if (data is Map) {
        _subtaskDeletedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('task:label_added', (data) {
      if (data is Map) {
        _taskLabelAddedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('task:label_removed', (data) {
      if (data is Map) {
        _taskLabelRemovedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('security:revoke', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Security revocation event received: $data');
        _securityRevokedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('chat:message_received', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Real-time chat message received: $data');
        _chatMessageController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('chat:reaction_updated', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Real-time reaction update received: $data');
        _chatReactionUpdatedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('chat:message_deleted', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Real-time message deleted received: $data');
        _chatMessageDeletedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('chat:message_pinned', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Real-time message pinned received: $data');
        _chatMessagePinnedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('call:incoming', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Real-time call:incoming received: $data');
        _callIncomingController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('call:accepted', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Real-time call:accepted received: $data');
        _callAcceptedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('call:rejected', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Real-time call:rejected received: $data');
        _callRejectedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('call:ended', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Real-time call:ended received: $data');
        _callEndedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('call:signal', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Real-time call:signal received: $data');
        _callSignalController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('chat:user_typing', (data) {
      if (data is Map) {
        _userTypingController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('notification:new_message', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Notification new message received: $data');
        _messageNotificationController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('notification:created', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Real-time notification received: $data');
        _notificationCreatedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('chat:messages_delivered', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Real-time messages delivered: $data');
        _messagesDeliveredController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('chat:messages_read', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Real-time messages read: $data');
        _messagesReadController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('auth:expired', (data) {
      debugPrint('[SocketService] Auth token expired on server: $data');
    });

    _socket!.connect();
  }

  void joinProject(String projectId) {
    if (_socket != null) {
      _socket!.emit('join:project', {'projectId': projectId});
      debugPrint('[SocketService] Joined project room: $projectId');
    }
  }

  void leaveProject(String projectId) {
    if (_socket != null) {
      _socket!.emit('leave:project', {'projectId': projectId});
      debugPrint('[SocketService] Left project room: $projectId');
    }
  }

  void joinChannel(String channelId) {
    _activeChannels.add(channelId);
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join:channel', {'channelId': channelId});
      debugPrint('[SocketService] Joined channel room: $channelId');
    }
  }

  void leaveChannel(String channelId) {
    _activeChannels.remove(channelId);
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave:channel', {'channelId': channelId});
      debugPrint('[SocketService] Left channel room: $channelId');
    }
  }

  void sendTyping(String channelId, bool isTyping) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('chat:typing', {'channelId': channelId, 'isTyping': isTyping});
    }
  }

  void sendCallSignal(String callId, String targetUserId, dynamic signal) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('call:signal', {
        'callId': callId,
        'targetUserId': targetUserId,
        'signal': signal,
      });
      debugPrint('[SocketService] Emitted call:signal to $targetUserId for call $callId');
    }
  }

  void renewAuth(String newAccessToken) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('auth:renew', {'accessToken': newAccessToken});
      debugPrint('[SocketService] Emitted auth:renew with refreshed token');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _connectionStateController.add(false);
  }

  void dispose() {
    disconnect();
    _connectionStateController.close();
    _taskCreatedController.close();
    _taskUpdatedController.close();
    _taskStatusChangedController.close();
    _taskDeletedController.close();
    _commentCreatedController.close();
    _subtaskCreatedController.close();
    _subtaskUpdatedController.close();
    _subtaskDeletedController.close();
    _taskLabelAddedController.close();
    _taskLabelRemovedController.close();
    _securityRevokedController.close();
    _chatMessageController.close();
    _chatReactionUpdatedController.close();
    _chatMessageDeletedController.close();
    _chatMessagePinnedController.close();
    _callIncomingController.close();
    _callAcceptedController.close();
    _callRejectedController.close();
    _callEndedController.close();
    _callSignalController.close();
    _userTypingController.close();
    _messageNotificationController.close();
    _notificationCreatedController.close();
    _messagesDeliveredController.close();
    _messagesReadController.close();
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final explicitUrl = ApiEndpoints.socketUrl.trim();
  final service = SocketService(
    tokenStorage: tokenStorage,
    socketUrl: explicitUrl.isNotEmpty ? explicitUrl : null,
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
