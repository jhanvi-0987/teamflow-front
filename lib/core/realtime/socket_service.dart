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
  final _securityRevokedController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onTaskCreated => _taskCreatedController.stream;
  Stream<Map<String, dynamic>> get onTaskUpdated => _taskUpdatedController.stream;
  Stream<Map<String, dynamic>> get onTaskStatusChanged => _taskStatusChangedController.stream;
  Stream<Map<String, dynamic>> get onTaskDeleted => _taskDeletedController.stream;
  Stream<Map<String, dynamic>> get onCommentCreated => _commentCreatedController.stream;
  Stream<Map<String, dynamic>> get onSecurityRevoked => _securityRevokedController.stream;

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
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setAuth({'token': token})
        .enableReconnection()
        .setReconnectionDelay(1000)
        .setReconnectionAttempts(10)
        .build();

    _socket = socket_io.io(_socketUrl, options);

    _socket!.onConnect((_) {
      debugPrint('[SocketService] Connected to $_socketUrl');
      _isConnected = true;
      _connectionStateController.add(true);
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SocketService] Disconnected');
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onConnectError((err) {
      debugPrint('[SocketService] Connection error: $err');
      _isConnected = false;
      _connectionStateController.add(false);
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

    _socket!.on('security:revoke', (data) {
      if (data is Map) {
        debugPrint('[SocketService] Security revocation event received: $data');
        _securityRevokedController.add(Map<String, dynamic>.from(data));
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
    _securityRevokedController.close();
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final service = SocketService(tokenStorage: tokenStorage);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
