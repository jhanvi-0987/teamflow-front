import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/realtime/socket_service.dart';
import 'package:mobile/core/webrtc/webrtc_service.dart';
import 'package:mobile/features/chat/domain/models/call_session_model.dart';
import 'package:mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:mobile/features/chat/presentation/providers/call_providers.dart';

class FakeChatRepository implements ChatRepository {
  CallSessionModel? lastInitiatedSession;
  String? lastEndedCallId;
  String? lastRejectedCallId;

  @override
  Future<CallSessionModel> initiateCall(
    String channelId,
    CallType type, {
    String? targetUserId,
  }) async {
    final session = CallSessionModel(
      id: 'call-101',
      channelId: channelId,
      callerId: 'user-caller',
      callerName: 'Caller',
      callerEmail: 'caller@teamflow.local',
      type: type,
      status: CallStatus.ringing,
      startedAt: DateTime.now(),
    );
    lastInitiatedSession = session;
    return session;
  }

  @override
  Future<CallSessionModel> acceptCall(String callId) async {
    return CallSessionModel(
      id: callId,
      channelId: 'ch-1',
      callerId: 'user-caller',
      callerName: 'Caller',
      callerEmail: 'caller@teamflow.local',
      type: CallType.voice,
      status: CallStatus.accepted,
      startedAt: DateTime.now(),
      answeredAt: DateTime.now(),
    );
  }

  @override
  Future<CallSessionModel> endCall(String callId) async {
    lastEndedCallId = callId;
    return CallSessionModel(
      id: callId,
      channelId: 'ch-1',
      callerId: 'user-caller',
      callerName: 'Caller',
      callerEmail: 'caller@teamflow.local',
      type: CallType.voice,
      status: CallStatus.ended,
      startedAt: DateTime.now(),
      endedAt: DateTime.now(),
    );
  }

  @override
  Future<CallSessionModel> rejectCall(String callId, {String? reason}) async {
    lastRejectedCallId = callId;
    return CallSessionModel(
      id: callId,
      channelId: 'ch-1',
      callerId: 'user-caller',
      callerName: 'Caller',
      callerEmail: 'caller@teamflow.local',
      type: CallType.voice,
      status: CallStatus.rejected,
      startedAt: DateTime.now(),
      endedAt: DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSocketService implements SocketService {
  final _incomingController = StreamController<Map<String, dynamic>>.broadcast();
  final _acceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _rejectedController = StreamController<Map<String, dynamic>>.broadcast();
  final _endedController = StreamController<Map<String, dynamic>>.broadcast();
  final _signalController = StreamController<Map<String, dynamic>>.broadcast();

  final List<Map<String, dynamic>> emittedSignals = [];

  @override
  Stream<Map<String, dynamic>> get onCallIncoming => _incomingController.stream;
  @override
  Stream<Map<String, dynamic>> get onCallAccepted => _acceptedController.stream;
  @override
  Stream<Map<String, dynamic>> get onCallRejected => _rejectedController.stream;
  @override
  Stream<Map<String, dynamic>> get onCallEnded => _endedController.stream;
  @override
  Stream<Map<String, dynamic>> get onCallSignal => _signalController.stream;

  @override
  void sendCallSignal(
    String callId,
    dynamic signal, {
    String? targetUserId,
    String? channelId,
  }) {
    emittedSignals.add({
      'callId': callId,
      'signal': signal,
      'targetUserId': targetUserId,
      'channelId': channelId,
    });
  }

  void emitIncoming(Map<String, dynamic> data) => _incomingController.add(data);
  void emitAccepted(Map<String, dynamic> data) => _acceptedController.add(data);
  void emitSignal(Map<String, dynamic> data) => _signalController.add(data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWebRTCService extends WebRTCService {
  bool isDisposed = false;
  bool isMuted = false;
  bool isVideo = false;
  bool isSpeaker = false;

  @override
  void setMicrophoneMute(bool muted) {
    isMuted = muted;
  }

  @override
  void setVideoEnabled(bool enabled) {
    isVideo = enabled;
  }

  @override
  Future<void> setSpeakerphoneOn(bool speakerOn) async {
    isSpeaker = speakerOn;
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeChatRepository repo;
  late FakeSocketService socket;
  late FakeWebRTCService webrtc;
  late CallNotifier notifier;

  setUp(() {
    repo = FakeChatRepository();
    socket = FakeSocketService();
    webrtc = FakeWebRTCService();
    notifier = CallNotifier(
      repository: repo,
      socketService: socket,
      webrtcService: webrtc,
    );
  });

  tearDown(() {
    notifier.dispose();
  });

  group('CallNotifier WebRTC Integration', () {
    test('audio and speaker toggles delegate to WebRTCService', () {
      expect(notifier.state.isAudioMuted, isFalse);
      expect(webrtc.isMuted, isFalse);

      notifier.toggleAudioMute();
      expect(notifier.state.isAudioMuted, isTrue);
      expect(webrtc.isMuted, isTrue);

      notifier.toggleSpeaker();
      // default isSpeakerOn is true, so toggle flips it to false
      expect(notifier.state.isSpeakerOn, isFalse);
      expect(webrtc.isSpeaker, isFalse);
    });

    test('video and camera toggles delegate to WebRTCService', () {
      expect(notifier.state.isVideoEnabled, isTrue);

      notifier.toggleVideo();
      expect(notifier.state.isVideoEnabled, isFalse);
      expect(webrtc.isVideo, isFalse);

      expect(notifier.state.isFrontCamera, isTrue);
      notifier.switchCamera();
      expect(notifier.state.isFrontCamera, isFalse);
    });

    test('endCall disposes WebRTC and sets status to ended', () async {
      await notifier.startCall(
        channelId: 'ch-99',
        channelName: 'Design Chat',
        type: CallType.voice,
      );

      expect(notifier.state.uiStatus, equals(CallUIStatus.outgoingRinging));

      await notifier.endCall();

      expect(webrtc.isDisposed, isTrue);
      expect(notifier.state.uiStatus, equals(CallUIStatus.ended));
      expect(repo.lastEndedCallId, equals('call-101'));
    });

    test('handles incoming call and sets speaker mode based on call type', () async {
      socket.emitIncoming({
        'callId': 'call-555',
        'channelId': 'ch-2',
        'channelName': 'General',
        'callerId': 'u-caller',
        'callerName': 'Alice',
        'type': 'VOICE',
      });

      await pumpEventQueue();

      expect(notifier.state.uiStatus, equals(CallUIStatus.incomingRinging));
      expect(notifier.state.remoteUserName, equals('Alice'));
      expect(notifier.state.remoteUserId, equals('u-caller'));
      expect(notifier.state.isSpeakerOn, isFalse); // Voice calls default to earpiece
    });
  });
}
