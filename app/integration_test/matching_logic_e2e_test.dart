import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app/services/session_service.dart';
import 'package:app/models/session_model.dart';
import 'package:app/firebase_options.dart';

// Run with: flutter test integration_test/matching_logic_e2e_test.dart -d windows
// Ensure Firebase Emulators are running on localhost:8080 (Firestore)

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Matching Engine E2E Logic', () {
    late FirebaseFirestore firestore;
    late SessionService sessionService;

    setUpAll(() async {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (e) {
        // Already initialized
      }
      
      firestore = FirebaseFirestore.instance;
      // Connect to emulator
      firestore.useFirestoreEmulator('127.0.0.1', 8080);
      
      sessionService = SessionService(firestore: firestore);
    });

    test('Seeker requests -> Cloud Function Matches -> Listener Accepts -> Payment Pending', () async {
      final seekerId = 'test_seeker_123';
      final listenerId = 'test_listener_456';

      // 1. Setup the dummy listener in Firestore so the Cloud Function can find them
      await firestore.collection('users').doc(listenerId).set({
        'uid': listenerId,
        'role': 'listener',
        'listenerData': {
          'isOnline': true,
        }
      });

      // 2. Seeker creates a session request
      final sessionId = await sessionService.createSessionRequest(
        seekerId: seekerId,
        seekerMoniker: 'Sad Panda',
        seekerMoodTag: 'Sad',
        seekerConcern: 'Feeling down',
        sessionType: 'SessionType.messages',
      );

      print('Session created: $sessionId');

      // 3. Wait for Cloud Function to assign the listener
      // We will listen to the stream and wait until listenerId is not null
      SessionModel? matchedSession;
      await for (final session in sessionService.streamSession(sessionId)) {
        if (session != null && session.listenerId != null) {
          matchedSession = session;
          break;
        }
      }

      print('Cloud function assigned listener: ${matchedSession!.listenerId}');
      expect(matchedSession.listenerId, listenerId);
      expect(matchedSession.status, 'pending');

      // 4. Listener stream picks it up
      // We check that streamIncomingRequests sees it
      final incoming = await sessionService.streamIncomingRequests(listenerId).first;
      expect(incoming.length, 1);
      expect(incoming.first.id, sessionId);

      // 5. Listener accepts
      await sessionService.acceptSession(sessionId);

      // 6. Seeker sees it become payment_pending
      SessionModel? paymentSession;
      await for (final session in sessionService.streamSession(sessionId)) {
        if (session != null && session.status == 'payment_pending') {
          paymentSession = session;
          break;
        }
      }

      print('Session advanced to payment_pending');
      expect(paymentSession!.status, 'payment_pending');

      // 7. Cleanup
      await firestore.collection('sessions').doc(sessionId).delete();
      await firestore.collection('users').doc(listenerId).delete();
    });
  });
}
