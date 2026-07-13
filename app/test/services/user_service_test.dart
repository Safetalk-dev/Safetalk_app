import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:app/services/user_service.dart';
import 'package:app/models/user_model.dart';

void main() {
  group('UserService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UserService userService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      userService = UserService(firestore: fakeFirestore);
    });

    test('getUser returns UserModel if document exists', () async {
      // Arrange
      await fakeFirestore.collection('users').doc('user123').set({
        'uid': 'user123',
        'email': 'test@test.com',
        'displayName': 'Mist Pebble',
        'role': 'user',
        'seekerData': {
          'walletBalance': 50.0,
          'preferredLanguages': ['en'],
          'safeCircle': []
        }
      });

      // Act
      final user = await userService.getUser('user123');

      // Assert
      expect(user, isNotNull);
      expect(user!.uid, 'user123');
      expect(user.role, 'user');
      expect(user.seekerData?.walletBalance, 50.0);
    });

    test('getUser returns null if document does not exist', () async {
      // Act
      final user = await userService.getUser('non_existent');

      // Assert
      expect(user, isNull);
    });

    test('createUser creates a new document in Firestore', () async {
      // Arrange
      final newUser = UserModel(
        uid: 'newuser',
        email: 'new@test.com',
        displayName: 'New User',
        role: 'listener',
        listenerData: ListenerData(
          isOnline: false,
          status: 'pending',
          languagesSpoken: ['en', 'hi'],
        ),
      );

      // Act
      await userService.createUser(newUser);

      // Assert
      final doc = await fakeFirestore.collection('users').doc('newuser').get();
      expect(doc.exists, true);
      expect(doc.data()?['role'], 'listener');
      expect(doc.data()?['listenerData']['languagesSpoken'], contains('hi'));
    });
  });
}
