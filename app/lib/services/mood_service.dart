import 'package:cloud_firestore/cloud_firestore.dart';

/// Service managing persistent mood check-ins under users/{uid}/mood_checkins (A4.5).
class MoodService {
  final FirebaseFirestore _firestore;

  MoodService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Persists a mood check-in score to Firestore
  Future<void> saveMoodCheckIn(
    String uid,
    double score,
    double graphScore,
  ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('mood_checkins')
        .add({
          'score': score,
          'graphScore': graphScore,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  /// Fetches recent mood scores in chronological order (oldest to newest) for plotting
  Future<List<double>> getRecentMoodScores(String uid, {int limit = 7}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('mood_checkins')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final scores = snapshot.docs
          .map((doc) => (doc.data()['graphScore'] as num?)?.toDouble() ?? 0.5)
          .toList();

      // Return chronological order (oldest -> newest) for Bezier curve plotting
      return scores.reversed.toList();
    } catch (_) {
      return [];
    }
  }
}
