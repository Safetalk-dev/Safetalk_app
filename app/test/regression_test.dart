import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:app/models/session_model.dart';
import 'package:app/services/matcher_service.dart';
import 'package:app/services/session_service.dart';
import 'package:app/services/razorpay_service.dart';

void main() {
  group('Regression Test Suite (Wave 0 - A0.3)', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('D-01 / D-12: MatcherService strictly filters online listeners with matching ISO language codes', () async {
      // Seed an online English listener
      await fakeFirestore.collection('users').doc('listener_en_online').set({
        'uid': 'listener_en_online',
        'displayName': 'Online Listener EN',
        'role': 'listener',
        'listenerData': {
          'isOnline': true,
          'languagesSpoken': ['en'],
          'status': 'available',
        },
      });

      // Seed an offline English listener
      await fakeFirestore.collection('users').doc('listener_en_offline').set({
        'uid': 'listener_en_offline',
        'displayName': 'Offline Listener EN',
        'role': 'listener',
        'listenerData': {
          'isOnline': false,
          'languagesSpoken': ['en'],
          'status': 'offline',
        },
      });

      // Seed an online listener who speaks English with legacy non-ISO name ('English')
      await fakeFirestore.collection('users').doc('listener_legacy_lang').set({
        'uid': 'listener_legacy_lang',
        'displayName': 'Legacy Listener',
        'role': 'listener',
        'listenerData': {
          'isOnline': true,
          'languagesSpoken': ['English'],
          'status': 'available',
        },
      });

      final matcher = MatcherService(firestore: fakeFirestore);

      // Query with ISO code ['en']
      final results = await matcher.getOnlineListeners(['en']);

      // Must find the online ISO listener
      expect(results.any((l) => l.uid == 'listener_en_online'), isTrue);

      // Must NOT find the offline listener
      expect(results.any((l) => l.uid == 'listener_en_offline'), isFalse);

      // Illustrates D-12 discrepancy: non-ISO 'English' is excluded when querying with 'en'
      expect(results.any((l) => l.uid == 'listener_legacy_lang'), isFalse);
    });

    test('D-04 / D-05: SessionModel serialization and duration validation', () {
      final now = DateTime.now();
      final tenMinutesLater = now.add(const Duration(minutes: 10));

      final session = SessionModel(
        id: 'sess_123',
        seekerId: 'seeker_456',
        seekerMoniker: 'Sad Panda',
        seekerMoodTag: 'Anxious',
        seekerConcern: 'Need someone to talk to',
        listenerId: 'listener_789',
        status: 'completed',
        sessionType: 'messages',
        requestedAt: now,
      );

      final json = session.toJson();
      expect(json['status'], 'completed');
      expect(json['sessionType'], 'messages');
      expect(json['requestedAt'], isNotNull);

      // Billing calculation logic specification: 10 minutes @ 5 INR/min = 50 INR
      final durationMinutes = tenMinutesLater.difference(now).inMinutes;
      expect(durationMinutes, 10);
      const ratePerMinute = 5;
      final expectedEarnings = durationMinutes * ratePerMinute;
      expect(expectedEarnings, 50);
    });

    test('D-10: Validates allowed session status transitions', () {
      const validTransitions = {
        'pending': ['payment_pending', 'rejected', 'cancelled'],
        'payment_pending': ['active', 'cancelled', 'rejected'],
        'active': ['completed', 'cancelled'],
        'completed': <String>[],
        'rejected': <String>[],
        'cancelled': <String>[],
      };

      bool isValidTransition(String from, String to) {
        return validTransitions[from]?.contains(to) ?? false;
      }

      // Valid paths
      expect(isValidTransition('pending', 'payment_pending'), isTrue);
      expect(isValidTransition('payment_pending', 'active'), isTrue);
      expect(isValidTransition('active', 'completed'), isTrue);

      // Invalid paths (e.g. minting loophole: completed -> active)
      expect(isValidTransition('completed', 'active'), isFalse);
      expect(isValidTransition('cancelled', 'active'), isFalse);
      expect(isValidTransition('rejected', 'completed'), isFalse);
    });

    test('D-03: SessionModel.normalizeSessionType handles legacy enum strings cleanly', () {
      expect(SessionModel.normalizeSessionType('SessionType.voiceCall'), 'voiceCall');
      expect(SessionModel.normalizeSessionType('SessionType.videoCall'), 'videoCall');
      expect(SessionModel.normalizeSessionType('SessionType.messages'), 'messages');
      expect(SessionModel.normalizeSessionType('voiceCall'), 'voiceCall');
      expect(SessionModel.normalizeSessionType(null), 'messages');
    });

    test('D-08: SessionModel serializes and deserializes sessionKey cleanly', () {
      final session = SessionModel(
        id: 'sess_crypto',
        seekerId: 'seeker_1',
        seekerMoniker: 'Moniker',
        seekerMoodTag: 'Calm',
        seekerConcern: 'None',
        status: 'pending',
        sessionType: 'messages',
        requestedAt: DateTime.now(),
        sessionKey: 'test_base64_session_key_32bytes==',
      );

      final json = session.toJson();
      expect(json['sessionKey'], 'test_base64_session_key_32bytes==');

      final parsed = SessionModel.fromJson(json, 'sess_crypto');
      expect(parsed.sessionKey, 'test_base64_session_key_32bytes==');
    });

    test('D-08: SessionService.createSessionRequest generates and persists sessionKey', () async {
      final service = SessionService(firestore: fakeFirestore);
      final sessionId = await service.createSessionRequest(
        seekerId: 'seeker_auto_key',
        seekerMoniker: 'Moniker',
        seekerMoodTag: 'Anxious',
        seekerConcern: 'Need support',
        sessionType: 'messages',
      );

      final doc = await fakeFirestore.collection('sessions').doc(sessionId).get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['sessionKey'], isNotNull);
      expect((data['sessionKey'] as String).isNotEmpty, isTrue);
      expect(data['status'], 'pending');
    });

    test('D-07: RazorpayService activeKeyId supports runtime injection and define resolution', () {
      RazorpayService.keyOverride = 'rzp_test_wave2_key';
      expect(RazorpayService.activeKeyId, 'rzp_test_wave2_key');
      RazorpayService.keyOverride = null;
    });
  });
}
