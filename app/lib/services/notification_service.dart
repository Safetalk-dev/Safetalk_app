import 'package:cloud_firestore/cloud_firestore.dart';

/// Service managing in-app notifications stored in users/{uid}/notifications (A4.1 - D-16).
class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  /// Streams notifications for a specific user ordered by createdAt descending
  Stream<List<Map<String, dynamic>>> streamNotifications(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] as String? ?? 'Notification',
              'body': data['body'] as String? ?? '',
              'type': data['type'] as String? ?? 'system',
              'read': data['read'] as bool? ?? false,
              'sessionId': data['sessionId'] as String?,
              'createdAt': _parseDate(data['createdAt']) ?? DateTime.now(),
            };
          }).toList();
        });
  }

  /// Marks a specific notification as read
  Future<void> markAsRead(String uid, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (_) {}
  }

  /// Deletes a single notification
  Future<void> deleteNotification(String uid, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (_) {}
  }

  /// Clears (deletes) all notifications for the given user
  Future<void> clearAll(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {}
  }
}
