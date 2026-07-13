import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:app/models/user_model.dart';
import 'package:app/services/matcher_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MatcherService matcherService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    matcherService = MatcherService(firestore: fakeFirestore);
  });

  group('MatcherService', () {
    test('returns only online listeners matching languages', () async {
      // 1. Online English Listener
      await fakeFirestore.collection('users').doc('1').set(UserModel(
            uid: '1',
            email: 'l1@test.com',
            displayName: 'L1',
            role: 'listener',
            listenerData: ListenerData(
              isOnline: true,
              status: 'active',
              languagesSpoken: ['en'],
            ),
          ).toJson());

      // 2. Offline English Listener
      await fakeFirestore.collection('users').doc('2').set(UserModel(
            uid: '2',
            email: 'l2@test.com',
            displayName: 'L2',
            role: 'listener',
            listenerData: ListenerData(
              isOnline: false,
              status: 'active',
              languagesSpoken: ['en'],
            ),
          ).toJson());

      // 3. Online Spanish Listener
      await fakeFirestore.collection('users').doc('3').set(UserModel(
            uid: '3',
            email: 'l3@test.com',
            displayName: 'L3',
            role: 'listener',
            listenerData: ListenerData(
              isOnline: true,
              status: 'active',
              languagesSpoken: ['es'],
            ),
          ).toJson());

      // 4. Online English User (not a listener)
      await fakeFirestore.collection('users').doc('4').set(UserModel(
            uid: '4',
            email: 'u1@test.com',
            displayName: 'U1',
            role: 'user',
            seekerData: SeekerData(
              walletBalance: 0,
              preferredLanguages: ['en'],
              safeCircle: [],
            ),
          ).toJson());

      final results = await matcherService.getOnlineListeners(['en']);

      expect(results.length, 1);
      expect(results.first.uid, '1');
    });

    test('returns empty if no languages provided', () async {
      await fakeFirestore.collection('users').doc('1').set(UserModel(
            uid: '1',
            email: 'l1@test.com',
            displayName: 'L1',
            role: 'listener',
            listenerData: ListenerData(
              isOnline: true,
              status: 'active',
              languagesSpoken: ['en'],
            ),
          ).toJson());

      final results = await matcherService.getOnlineListeners([]);
      expect(results, isEmpty);
    });
  });
}
