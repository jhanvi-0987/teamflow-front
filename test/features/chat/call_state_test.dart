import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/chat/domain/models/call_session_model.dart';
import 'package:mobile/features/chat/presentation/providers/call_providers.dart';

void main() {
  group('CallState', () {
    test('default state has correct initial values', () {
      const state = CallState();

      expect(state.uiStatus, equals(CallUIStatus.idle));
      expect(state.session, isNull);
      expect(state.channelId, isNull);
      expect(state.channelName, isNull);
      expect(state.remoteUserName, isNull);
      expect(state.callType, equals(CallType.voice));
      expect(state.isAudioMuted, isFalse);
      expect(state.isVideoEnabled, isTrue);
      expect(state.isSpeakerOn, isTrue);
      expect(state.isFrontCamera, isTrue);
      expect(state.durationSeconds, equals(0));
      expect(state.isActive, isFalse);
      expect(state.isConnected, isFalse);
      expect(state.isVideo, isFalse);
    });

    test('isActive returns true only for ringing and connected statuses', () {
      expect(const CallState(uiStatus: CallUIStatus.idle).isActive, isFalse);
      expect(const CallState(uiStatus: CallUIStatus.outgoingRinging).isActive, isTrue);
      expect(const CallState(uiStatus: CallUIStatus.incomingRinging).isActive, isTrue);
      expect(const CallState(uiStatus: CallUIStatus.connected).isActive, isTrue);
      expect(const CallState(uiStatus: CallUIStatus.ended).isActive, isFalse);
    });

    test('isConnected returns true only when connected', () {
      expect(const CallState(uiStatus: CallUIStatus.idle).isConnected, isFalse);
      expect(const CallState(uiStatus: CallUIStatus.outgoingRinging).isConnected, isFalse);
      expect(const CallState(uiStatus: CallUIStatus.connected).isConnected, isTrue);
    });

    test('isVideo correctly tracks callType', () {
      expect(const CallState(callType: CallType.voice).isVideo, isFalse);
      expect(const CallState(callType: CallType.video).isVideo, isTrue);
    });

    test('formattedDuration displays mm:ss with zero-padding', () {
      expect(const CallState(durationSeconds: 0).formattedDuration, equals('00:00'));
      expect(const CallState(durationSeconds: 9).formattedDuration, equals('00:09'));
      expect(const CallState(durationSeconds: 65).formattedDuration, equals('01:05'));
      expect(const CallState(durationSeconds: 600).formattedDuration, equals('10:00'));
    });

    test('copyWith updates specified fields and leaves others intact', () {
      const initial = CallState(
        uiStatus: CallUIStatus.idle,
        channelId: 'ch-1',
        channelName: 'General',
        callType: CallType.voice,
      );

      final updated = initial.copyWith(
        uiStatus: CallUIStatus.connected,
        durationSeconds: 42,
        isAudioMuted: true,
      );

      expect(updated.uiStatus, equals(CallUIStatus.connected));
      expect(updated.channelId, equals('ch-1'));
      expect(updated.channelName, equals('General'));
      expect(updated.callType, equals(CallType.voice));
      expect(updated.durationSeconds, equals(42));
      expect(updated.isAudioMuted, isTrue);
      expect(updated.isSpeakerOn, isTrue);
    });

    test('copyWith clearSession sets session to null', () {
      final session = CallSessionModel(
        id: 's-1',
        channelId: 'ch-1',
        callerId: 'u-1',
        callerName: 'Bob',
        callerEmail: 'bob@example.com',
        type: CallType.voice,
        status: CallStatus.ringing,
        startedAt: DateTime.now(),
      );

      final initial = CallState(
        uiStatus: CallUIStatus.connected,
        session: session,
      );

      final updated = initial.copyWith(clearSession: true);

      expect(updated.session, isNull);
    });
  });
}
