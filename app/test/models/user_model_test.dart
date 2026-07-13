import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user_model.dart';

void main() {
  group('UserModel Parsing', () {
    test('parses a basic Seeker user correctly from JSON', () {
      final json = {
        'uid': 'user123',
        'email': 'seeker@test.com',
        'displayName': 'Mist Pebble',
        'role': 'user',
        'seekerData': {
          'walletBalance': 50.0,
          'preferredLanguages': ['en', 'hi'],
          'safeCircle': ['listener456']
        }
      };

      final user = UserModel.fromJson(json);

      expect(user.uid, 'user123');
      expect(user.role, 'user');
      expect(user.displayName, 'Mist Pebble');
      expect(user.seekerData, isNotNull);
      expect(user.seekerData?.walletBalance, 50.0);
      expect(user.seekerData?.preferredLanguages, containsAll(['en', 'hi']));
      expect(user.listenerData, isNull);
    });

    test('parses a basic Listener user correctly from JSON', () {
      final json = {
        'uid': 'listener456',
        'email': 'listener@test.com',
        'displayName': 'Calm Ocean',
        'role': 'listener',
        'listenerData': {
          'isOnline': true,
          'status': 'active',
          'languagesSpoken': ['en', 'es', 'hi'],
          'stats': {
            'rating': 4.9,
            'minutesListened': 100
          }
        }
      };

      final user = UserModel.fromJson(json);

      expect(user.uid, 'listener456');
      expect(user.role, 'listener');
      expect(user.seekerData, isNull);
      expect(user.listenerData, isNotNull);
      expect(user.listenerData?.isOnline, true);
      expect(user.listenerData?.languagesSpoken, containsAll(['en', 'es', 'hi']));
      expect(user.listenerData?.stats?.rating, 4.9);
    });

    test('serializes back to JSON correctly', () {
      final user = UserModel(
        uid: 'user789',
        email: 'test@test.com',
        displayName: 'Test',
        role: 'user',
        seekerData: SeekerData(
          walletBalance: 10.0,
          preferredLanguages: ['en'],
          safeCircle: [],
        ),
      );

      final json = user.toJson();

      expect(json['uid'], 'user789');
      expect(json['role'], 'user');
      expect(json['seekerData'], isNotNull);
      expect(json['seekerData']['preferredLanguages'], contains('en'));
    });
  });
}
