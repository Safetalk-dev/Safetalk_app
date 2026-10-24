import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:app/services/notification_service.dart';

void main() {
  group('NotificationService (A4.1 - D-16)', () {
    late FakeFirebaseFirestore fakeFirestore;
    late NotificationService notificationService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      notificationService = NotificationService(firestore: fakeFirestore);
    });

    test(
      'streamNotifications returns empty list when no notifications exist',
      () async {
        final list = await notificationService
            .streamNotifications('user_empty')
            .first;
        expect(list, isEmpty);
      },
    );

    test('streamNotifications returns ordered list of notifications', () async {
      const uid = 'user_test_notifs';
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(minutes: 5));

      final notifsRef = fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('notifications');

      await notifsRef.doc('n1').set({
        'title': 'Older Alert',
        'body': 'First message',
        'type': 'system',
        'read': false,
        'createdAt': earlier,
      });

      await notifsRef.doc('n2').set({
        'title': 'Newer Alert',
        'body': 'Second message',
        'type': 'match_request',
        'read': false,
        'sessionId': 'sess_123',
        'createdAt': now,
      });

      final list = await notificationService.streamNotifications(uid).first;
      expect(list.length, 2);

      // Ordered descending by createdAt: n2 is first
      expect(list[0]['id'], 'n2');
      expect(list[0]['title'], 'Newer Alert');
      expect(list[0]['type'], 'match_request');
      expect(list[0]['sessionId'], 'sess_123');
      expect(list[0]['read'], false);

      expect(list[1]['id'], 'n1');
      expect(list[1]['title'], 'Older Alert');
    });

    test('markAsRead updates read status to true', () async {
      const uid = 'user_read_test';
      final notifRef = fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc('n_read');
      await notifRef.set({
        'title': 'Test',
        'read': false,
        'createdAt': DateTime.now(),
      });

      await notificationService.markAsRead(uid, 'n_read');
      final updated = await notifRef.get();
      expect(updated.data()!['read'], true);
    });

    test('deleteNotification removes single document', () async {
      const uid = 'user_del_test';
      final notifRef = fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc('n_del');
      await notifRef.set({'title': 'To Delete', 'createdAt': DateTime.now()});

      await notificationService.deleteNotification(uid, 'n_del');
      final deleted = await notifRef.get();
      expect(deleted.exists, false);
    });

    test('clearAll deletes all notifications for user', () async {
      const uid = 'user_clear_test';
      final notifsRef = fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('notifications');

      await notifsRef.doc('n1').set({
        'title': '1',
        'createdAt': DateTime.now(),
      });
      await notifsRef.doc('n2').set({
        'title': '2',
        'createdAt': DateTime.now(),
      });
      await notifsRef.doc('n3').set({
        'title': '3',
        'createdAt': DateTime.now(),
      });

      await notificationService.clearAll(uid);

      final snapshot = await notifsRef.get();
      expect(snapshot.docs, isEmpty);
    });
  });
}
