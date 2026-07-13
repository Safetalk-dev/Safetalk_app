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
  });

  factory SessionModel.fromJson(Map<String, dynamic> json, String id) {
    return SessionModel(
      id: id,
      seekerId: json['seekerId'] as String? ?? '',
      seekerMoniker: json['seekerMoniker'] as String? ?? 'Anonymous',
      seekerMoodTag: json['seekerMoodTag'] as String? ?? 'Neutral',
      seekerConcern: json['seekerConcern'] as String? ?? '',
      listenerId: json['listenerId'] as String?,
      status: json['status'] as String? ?? 'pending',
      rejectedBy: (json['rejectedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sessionType: json['sessionType'] as String? ?? 'messages',
      requestedAt: (json['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
    };
  }
}
