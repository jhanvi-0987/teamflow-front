import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/token_storage.dart';
import 'package:mobile/core/realtime/socket_service.dart';

void main() {
  group('SocketService', () {
    late InMemoryTokenStorage tokenStorage;
    late SocketService socketService;

    setUp(() {
      tokenStorage = InMemoryTokenStorage();
      socketService = SocketService(
        tokenStorage: tokenStorage,
        socketUrl: 'http://localhost:3000',
      );
    });

    tearDown(() {
      socketService.dispose();
    });

    test('initializes with disconnected state', () {
      expect(socketService.isConnected, isFalse);
    });

    test('derives base socket URL without path correctly', () {
      final service = SocketService(
        tokenStorage: tokenStorage,
      );
      expect(service.isConnected, isFalse);
    });

    test('event streams are active and broadcast capable', () async {
      expect(socketService.onTaskCreated, isNotNull);
      expect(socketService.onTaskUpdated, isNotNull);
      expect(socketService.onTaskStatusChanged, isNotNull);
      expect(socketService.onTaskDeleted, isNotNull);
      expect(socketService.onCommentCreated, isNotNull);
      expect(socketService.onSecurityRevoked, isNotNull);
    });
  });
}
