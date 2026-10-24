import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:app/services/mood_service.dart';

void main() {
  group('MoodService (A4.5)', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MoodService moodService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      moodService = MoodService(firestore: fakeFirestore);
    });

    test(
      'getRecentMoodScores returns empty list when no check-ins exist',
      () async {
        final scores = await moodService.getRecentMoodScores('user_no_mood');
        expect(scores, isEmpty);
      },
    );

    test(
      'saveMoodCheckIn saves document to mood_checkins subcollection',
      () async {
        const uid = 'user_save_mood';
        await moodService.saveMoodCheckIn(uid, 8.0, 0.8);

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('mood_checkins')
            .get();

        expect(snapshot.docs.length, 1);
        final data = snapshot.docs.first.data();
        expect(data['score'], 8.0);
        expect(data['graphScore'], 0.8);
        expect(data['timestamp'], isNotNull);
      },
    );

    test(
      'getRecentMoodScores returns scores in chronological order capped to limit',
      () async {
        const uid = 'user_history_mood';
        final now = DateTime.now();

        final col = fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('mood_checkins');
        // Insert 3 check-ins with increasing timestamps
        await col.add({
          'graphScore': 0.3,
          'timestamp': now.subtract(const Duration(days: 2)),
        });
        await col.add({
          'graphScore': 0.6,
          'timestamp': now.subtract(const Duration(days: 1)),
        });
        await col.add({'graphScore': 0.9, 'timestamp': now});

        final scores = await moodService.getRecentMoodScores(uid, limit: 7);
        expect(scores.length, 3);
        // Chronological order (oldest to newest): 0.3 -> 0.6 -> 0.9
        expect(scores[0], 0.3);
        expect(scores[1], 0.6);
        expect(scores[2], 0.9);
      },
    );
  });
}
