import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/chat/domain/models/call_session_model.dart';

void main() {
  group('CallType', () {
    test('fromString converts strings correctly', () {
      expect(CallType.fromString('VOICE'), equals(CallType.voice));
      expect(CallType.fromString('voice'), equals(CallType.voice));
      expect(CallType.fromString('VIDEO'), equals(CallType.video));
      expect(CallType.fromString('video'), equals(CallType.video));
      expect(CallType.fromString('unknown'), equals(CallType.voice));
      expect(CallType.fromString(null), equals(CallType.voice));
    });

    test('toApiString serializes to uppercase string', () {
      expect(CallType.voice.toApiString(), equals('VOICE'));
      expect(CallType.video.toApiString(), equals('VIDEO'));
    });
  });

  group('CallStatus', () {
    test('fromString converts all statuses correctly', () {
      expect(CallStatus.fromString('RINGING'), equals(CallStatus.ringing));
      expect(CallStatus.fromString('ACCEPTED'), equals(CallStatus.accepted));
      expect(CallStatus.fromString('REJECTED'), equals(CallStatus.rejected));
      expect(CallStatus.fromString('MISSED'), equals(CallStatus.missed));
      expect(CallStatus.fromString('ENDED'), equals(CallStatus.ended));
      expect(CallStatus.fromString('BUSY'), equals(CallStatus.busy));
      expect(CallStatus.fromString('unknown'), equals(CallStatus.ringing));
      expect(CallStatus.fromString(null), equals(CallStatus.ringing));
    });

    test('name.toUpperCase serializes correctly', () {
      expect(CallStatus.ringing.name.toUpperCase(), equals('RINGING'));
      expect(CallStatus.accepted.name.toUpperCase(), equals('ACCEPTED'));
      expect(CallStatus.rejected.name.toUpperCase(), equals('REJECTED'));
      expect(CallStatus.missed.name.toUpperCase(), equals('MISSED'));
      expect(CallStatus.ended.name.toUpperCase(), equals('ENDED'));
      expect(CallStatus.busy.name.toUpperCase(), equals('BUSY'));
    });
  });

  group('CallSessionModel', () {
    test('parses from standard JSON correctly', () {
      final json = {
        'id': 'call-123',
        'channelId': 'chan-456',
        'callerId': 'user-1',
        'type': 'VIDEO',
        'status': 'ACCEPTED',
        'startedAt': '2026-10-30T10:00:00.000Z',
        'answeredAt': '2026-10-30T10:00:05.000Z',
        'endedAt': '2026-10-30T10:05:00.000Z',
        'durationSeconds': 295,
        'caller': {
          'id': 'user-1',
          'name': 'Alice Wonder',
          'email': 'alice@example.com',
        },
      };

      final session = CallSessionModel.fromJson(json);

      expect(session.id, equals('call-123'));
      expect(session.channelId, equals('chan-456'));
      expect(session.callerId, equals('user-1'));
      expect(session.type, equals(CallType.video));
      expect(session.status, equals(CallStatus.accepted));
      expect(session.startedAt, isA<DateTime>());
      expect(session.answeredAt, isA<DateTime>());
      expect(session.endedAt, isA<DateTime>());
      expect(session.durationSeconds, equals(295));
      expect(session.callerName, equals('Alice Wonder'));
      expect(session.callerEmail, equals('alice@example.com'));
      expect(session.isVideo, isTrue);
      expect(session.isVoice, isFalse);
      expect(session.isConnected, isTrue);
    });

    test('handles fallback fields for socket payload format (callId, callerName)', () {
      final json = {
        'callId': 'call-socket-99',
        'channelId': 'chan-789',
        'callerId': 'user-2',
        'callerName': 'Bob Builder',
        'type': 'VOICE',
        'status': 'RINGING',
        'startedAt': '2026-10-30T11:00:00.000Z',
      };

      final session = CallSessionModel.fromJson(json);

      expect(session.id, equals('call-socket-99'));
      expect(session.callerName, equals('Bob Builder'));
      expect(session.isVoice, isTrue);
      expect(session.isVideo, isFalse);
      expect(session.isConnected, isFalse);
    });

    test('formats duration into mm:ss', () {
      final sessionShort = CallSessionModel(
        id: 'c1',
        channelId: 'ch1',
        callerId: 'u1',
        callerName: 'Alice',
        callerEmail: 'alice@example.com',
        type: CallType.voice,
        status: CallStatus.ended,
        startedAt: DateTime.now(),
        durationSeconds: 75,
      );
      expect(sessionShort.formattedDuration, equals('01:15'));

      final sessionZero = CallSessionModel(
        id: 'c2',
        channelId: 'ch1',
        callerId: 'u1',
        callerName: 'Alice',
        callerEmail: 'alice@example.com',
        type: CallType.voice,
        status: CallStatus.ended,
        startedAt: DateTime.now(),
        durationSeconds: 0,
      );
      expect(sessionZero.formattedDuration, equals('00:00'));
    });

    test('copyWith works correctly', () {
      final original = CallSessionModel(
        id: 'call-1',
        channelId: 'ch-1',
        callerId: 'u-1',
        callerName: 'Alice',
        callerEmail: 'alice@example.com',
        type: CallType.voice,
        status: CallStatus.ringing,
        startedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        status: CallStatus.accepted,
        durationSeconds: 120,
      );

      expect(updated.id, equals('call-1'));
      expect(updated.status, equals(CallStatus.accepted));
      expect(updated.durationSeconds, equals(120));
      expect(updated.type, equals(CallType.voice));
    });
  });
}
