import 'package:equatable/equatable.dart';

enum CallType {
  voice,
  video;

  String toApiString() => name.toUpperCase();

  static CallType fromString(String? val) {
    if (val != null && val.toLowerCase() == 'video') return CallType.video;
    return CallType.voice;
  }
}

enum CallStatus {
  ringing,
  accepted,
  rejected,
  missed,
  ended,
  busy;

  static CallStatus fromString(String? val) {
    if (val == null) return CallStatus.ringing;
    switch (val.toLowerCase()) {
      case 'accepted':
        return CallStatus.accepted;
      case 'rejected':
        return CallStatus.rejected;
      case 'missed':
        return CallStatus.missed;
      case 'ended':
        return CallStatus.ended;
      case 'busy':
        return CallStatus.busy;
      case 'ringing':
      default:
        return CallStatus.ringing;
    }
  }
}

class CallSessionModel extends Equatable {
  final String id;
  final String channelId;
  final String callerId;
  final String callerName;
  final String callerEmail;
  final CallType type;
  final CallStatus status;
  final DateTime startedAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int durationSeconds;

  const CallSessionModel({
    required this.id,
    required this.channelId,
    required this.callerId,
    required this.callerName,
    required this.callerEmail,
    required this.type,
    required this.status,
    required this.startedAt,
    this.answeredAt,
    this.endedAt,
    this.durationSeconds = 0,
  });

  bool get isVideo => type == CallType.video;
  bool get isVoice => type == CallType.voice;
  bool get isConnected => status == CallStatus.accepted;

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  CallSessionModel copyWith({
    String? id,
    String? channelId,
    String? callerId,
    String? callerName,
    String? callerEmail,
    CallType? type,
    CallStatus? status,
    DateTime? startedAt,
    DateTime? answeredAt,
    DateTime? endedAt,
    int? durationSeconds,
  }) {
    return CallSessionModel(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerEmail: callerEmail ?? this.callerEmail,
      type: type ?? this.type,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  factory CallSessionModel.fromJson(Map<String, dynamic> json) {
    final caller = json['caller'] as Map<String, dynamic>?;
    return CallSessionModel(
      id: json['id'] as String? ?? json['callId'] as String? ?? '',
      channelId: json['channelId'] as String? ?? '',
      callerId: json['callerId'] as String? ?? caller?['id'] as String? ?? '',
      callerName: json['callerName'] as String? ??
          caller?['name'] as String? ??
          caller?['email']?.toString().split('@').first ??
          'Teammate',
      callerEmail:
          json['callerEmail'] as String? ?? caller?['email'] as String? ?? '',
      type: CallType.fromString(json['type']?.toString() ?? 'VOICE'),
      status: CallStatus.fromString(json['status']?.toString() ?? 'RINGING'),
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
              : DateTime.now()),
      answeredAt: json['answeredAt'] != null
          ? DateTime.tryParse(json['answeredAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'] as String)
          : null,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'channelId': channelId,
        'callerId': callerId,
        'callerName': callerName,
        'callerEmail': callerEmail,
        'type': type.toApiString(),
        'status': status.name.toUpperCase(),
        'startedAt': startedAt.toIso8601String(),
        'answeredAt': answeredAt?.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'durationSeconds': durationSeconds,
      };

  @override
  List<Object?> get props => [
        id,
        channelId,
        callerId,
        callerName,
        callerEmail,
        type,
        status,
        startedAt,
        answeredAt,
        endedAt,
        durationSeconds,
      ];
}
