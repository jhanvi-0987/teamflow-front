import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../domain/models/call_session_model.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_providers.dart';

enum CallUIStatus {
  idle,
  outgoingRinging,
  incomingRinging,
  connected,
  ended,
}

class CallState extends Equatable {
  final CallUIStatus uiStatus;
  final CallSessionModel? session;
  final String? channelId;
  final String? channelName;
  final String? remoteUserName;
  final String? remoteUserId;
  final CallType callType;
  final bool isAudioMuted;
  final bool isVideoEnabled;
  final bool isSpeakerOn;
  final bool isFrontCamera;
  final int durationSeconds;

  const CallState({
    this.uiStatus = CallUIStatus.idle,
    this.session,
    this.channelId,
    this.channelName,
    this.remoteUserName,
    this.remoteUserId,
    this.callType = CallType.voice,
    this.isAudioMuted = false,
    this.isVideoEnabled = true,
    this.isSpeakerOn = true,
    this.isFrontCamera = true,
    this.durationSeconds = 0,
  });

  bool get isActive =>
      uiStatus == CallUIStatus.outgoingRinging ||
      uiStatus == CallUIStatus.incomingRinging ||
      uiStatus == CallUIStatus.connected;

  bool get isConnected => uiStatus == CallUIStatus.connected;
  bool get isVideo => callType == CallType.video;

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  CallState copyWith({
    CallUIStatus? uiStatus,
    CallSessionModel? session,
    String? channelId,
    String? channelName,
    String? remoteUserName,
    String? remoteUserId,
    CallType? callType,
    bool? isAudioMuted,
    bool? isVideoEnabled,
    bool? isSpeakerOn,
    bool? isFrontCamera,
    int? durationSeconds,
    bool clearSession = false,
  }) {
    return CallState(
      uiStatus: uiStatus ?? this.uiStatus,
      session: clearSession ? null : (session ?? this.session),
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      remoteUserName: remoteUserName ?? this.remoteUserName,
      remoteUserId: remoteUserId ?? this.remoteUserId,
      callType: callType ?? this.callType,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  @override
  List<Object?> get props => [
        uiStatus,
        session,
        channelId,
        channelName,
        remoteUserName,
        remoteUserId,
        callType,
        isAudioMuted,
        isVideoEnabled,
        isSpeakerOn,
        isFrontCamera,
        durationSeconds,
      ];
}

class CallNotifier extends StateNotifier<CallState> {
  final ChatRepository _repository;
  final SocketService _socketService;
  StreamSubscription? _incomingSub;
  StreamSubscription? _acceptedSub;
  StreamSubscription? _rejectedSub;
  StreamSubscription? _endedSub;
  Timer? _durationTimer;
  Timer? _autoResetTimer;

  CallNotifier({
    required ChatRepository repository,
    required SocketService socketService,
  })  : _repository = repository,
        _socketService = socketService,
        super(const CallState()) {
    _init();
  }

  void _init() {
    _incomingSub = _socketService.onCallIncoming.listen((data) {
      if (!mounted) return;
      // If already in a call, reject with busy reason
      if (state.isActive) {
        final callId = data['callId'] as String?;
        if (callId != null) {
          _repository.rejectCall(callId, reason: 'busy').ignore();
        }
        return;
      }

      final session = CallSessionModel.fromJson(data);
      final callerName = data['callerName'] as String? ?? 'Teammate';
      final callerId = data['callerId'] as String? ?? '';
      final channelId = data['channelId'] as String? ?? '';
      final channelName = data['channelName'] as String? ?? callerName;
      final type = CallType.fromString(data['type']?.toString() ?? 'VOICE');

      state = CallState(
        uiStatus: CallUIStatus.incomingRinging,
        session: session,
        channelId: channelId,
        channelName: channelName,
        remoteUserName: callerName,
        remoteUserId: callerId,
        callType: type,
        isVideoEnabled: type == CallType.video,
      );
    });

    _acceptedSub = _socketService.onCallAccepted.listen((data) {
      if (!mounted) return;
      if (state.session != null && data['callId'] == state.session!.id) {
        _startTimer();
        state = state.copyWith(
          uiStatus: CallUIStatus.connected,
          remoteUserName: data['responderName'] as String? ?? state.remoteUserName,
        );
      }
    });

    _rejectedSub = _socketService.onCallRejected.listen((data) {
      if (!mounted) return;
      if (state.session != null && data['callId'] == state.session!.id) {
        _stopTimer();
        state = state.copyWith(uiStatus: CallUIStatus.ended);
        _scheduleAutoReset();
      }
    });

    _endedSub = _socketService.onCallEnded.listen((data) {
      if (!mounted) return;
      if (state.session != null && data['callId'] == state.session!.id) {
        _stopTimer();
        state = state.copyWith(uiStatus: CallUIStatus.ended);
        _scheduleAutoReset();
      }
    });
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      state = state.copyWith(durationSeconds: state.durationSeconds + 1);
    });
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _scheduleAutoReset() {
    _autoResetTimer?.cancel();
    _autoResetTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      state = const CallState();
    });
  }

  Future<void> startCall({
    required String channelId,
    required String channelName,
    required CallType type,
    String? targetUserId,
    String? remoteUserName,
  }) async {
    _autoResetTimer?.cancel();
    _stopTimer();

    state = CallState(
      uiStatus: CallUIStatus.outgoingRinging,
      channelId: channelId,
      channelName: channelName,
      remoteUserName: remoteUserName ?? channelName,
      remoteUserId: targetUserId,
      callType: type,
      isVideoEnabled: type == CallType.video,
    );

    try {
      final session = await _repository.initiateCall(
        channelId,
        type,
        targetUserId: targetUserId,
      );
      if (!mounted) return;
      state = state.copyWith(session: session);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(uiStatus: CallUIStatus.ended);
      _scheduleAutoReset();
    }
  }

  Future<void> acceptCall() async {
    if (state.session == null) return;
    try {
      final updated = await _repository.acceptCall(state.session!.id);
      if (!mounted) return;
      _startTimer();
      state = state.copyWith(
        uiStatus: CallUIStatus.connected,
        session: updated,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(uiStatus: CallUIStatus.ended);
      _scheduleAutoReset();
    }
  }

  Future<void> rejectCall({String? reason}) async {
    if (state.session == null) {
      state = const CallState();
      return;
    }
    try {
      await _repository.rejectCall(state.session!.id, reason: reason);
    } catch (_) {}
    if (!mounted) return;
    state = const CallState();
  }

  Future<void> endCall() async {
    _stopTimer();
    final callId = state.session?.id;
    state = state.copyWith(uiStatus: CallUIStatus.ended);
    _scheduleAutoReset();

    if (callId != null) {
      try {
        await _repository.endCall(callId);
      } catch (_) {}
    }
  }

  void toggleAudioMute() {
    state = state.copyWith(isAudioMuted: !state.isAudioMuted);
  }

  void toggleVideo() {
    state = state.copyWith(isVideoEnabled: !state.isVideoEnabled);
  }

  void toggleSpeaker() {
    state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);
  }

  void switchCamera() {
    state = state.copyWith(isFrontCamera: !state.isFrontCamera);
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    _acceptedSub?.cancel();
    _rejectedSub?.cancel();
    _endedSub?.cancel();
    _durationTimer?.cancel();
    _autoResetTimer?.cancel();
    super.dispose();
  }
}

final callStateProvider =
    StateNotifierProvider<CallNotifier, CallState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  final socket = ref.watch(socketServiceProvider);
  return CallNotifier(repository: repo, socketService: socket);
});
