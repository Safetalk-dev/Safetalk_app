import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String seekerId;
  final String seekerMoniker;
  final String seekerMoodTag;
  final String seekerConcern;
  final String? listenerId;
  final String status;
  final List<String> rejectedBy;
  final String sessionType;
  final DateTime requestedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? sessionKey;

  SessionModel({
    required this.id,
    required this.seekerId,
    required this.seekerMoniker,
    required this.seekerMoodTag,
    required this.seekerConcern,
    this.listenerId,
    required this.status,
    this.rejectedBy = const [],
    required this.sessionType,
    required this.requestedAt,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.sessionKey,
  });

  static String normalizeSessionType(dynamic raw) {
    if (raw == null) return 'messages';
    final str = raw.toString();
    if (str == 'SessionType.voiceCall' || str == 'voiceCall') {
      return 'voiceCall';
    }
    if (str == 'SessionType.videoCall' || str == 'videoCall') {
      return 'videoCall';
    }
    if (str == 'SessionType.messages' || str == 'messages') return 'messages';
    return str;
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  factory SessionModel.fromJson(Map<String, dynamic> json, String id) {
    return SessionModel(
      id: id,
      seekerId: json['seekerId'] as String? ?? '',
      seekerMoniker: json['seekerMoniker'] as String? ?? 'Anonymous',
      seekerMoodTag: json['seekerMoodTag'] as String? ?? 'Neutral',
      seekerConcern: json['seekerConcern'] as String? ?? '',
      listenerId: json['listenerId'] as String?,
      status: json['status'] as String? ?? 'pending',
      rejectedBy:
          (json['rejectedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sessionType: normalizeSessionType(json['sessionType']),
      requestedAt:
          _parseDate(json['requestedAt']) ??
          _parseDate(json['createdAt']) ??
          DateTime.now(),
      startedAt: _parseDate(json['startedAt']),
      completedAt: _parseDate(json['completedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      sessionKey: json['sessionKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seekerId': seekerId,
      'seekerMoniker': seekerMoniker,
      'seekerMoodTag': seekerMoodTag,
      'seekerConcern': seekerConcern,
      if (listenerId != null) 'listenerId': listenerId,
      'status': status,
      'rejectedBy': rejectedBy,
      'sessionType': sessionType,
      'requestedAt': Timestamp.fromDate(requestedAt),
      if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (sessionKey != null) 'sessionKey': sessionKey,
    };
  }
}
