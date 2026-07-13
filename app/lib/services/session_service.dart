import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/models/session_model.dart';

class SessionService {
  final FirebaseFirestore _firestore;

  SessionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Creates a new session request
  Future<String> createSessionRequest({
    required String seekerId,
    required String seekerMoniker,
    required String seekerMoodTag,
    required String seekerConcern,
    required String sessionType,
  }) async {
    final docRef = _firestore.collection('sessions').doc();
    final session = SessionModel(
      id: docRef.id,
      seekerId: seekerId,
      seekerMoniker: seekerMoniker,
      seekerMoodTag: seekerMoodTag,
      seekerConcern: seekerConcern,
      status: 'pending',
      sessionType: sessionType,
      requestedAt: DateTime.now(),
    );

    await docRef.set(session.toJson());
    return docRef.id;
  }

  /// Listens to session updates
  Stream<SessionModel?> streamSession(String sessionId) {
    return _firestore.collection('sessions').doc(sessionId).snapshots().map(
      (doc) {
        if (!doc.exists || doc.data() == null) return null;
        return SessionModel.fromJson(doc.data()!, doc.id);
      },
    );
  }

  /// Listens to incoming requests for a listener
  Stream<List<SessionModel>> streamIncomingRequests(String listenerId) {
    return _firestore
        .collection('sessions')
        .where('listenerId', isEqualTo: listenerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SessionModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // CHAT METHODS
  // ---------------------------------------------------------------------------

  /// Sends a message to a session's chat subcollection.
  /// Note: Encryption should ideally happen before this point.
  Future<void> sendMessage(String sessionId, String text, String senderId) async {
    final msgData = {
      'text': text,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
    };
    
    await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .add(msgData);
  }

  /// Streams messages from a session's chat subcollection, ordered by time.
  Stream<List<Map<String, dynamic>>> streamMessages(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'text': data['text'] ?? '',
          'senderId': data['senderId'] ?? '',
          'timestamp': data['timestamp'],
        };
      }).toList();
    });
  }

  /// Listener accepts session
  Future<void> acceptSession(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': 'payment_pending',
    });
  }

  /// Listener rejects session
  Future<void> rejectSession(String sessionId, String listenerId) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'listenerId': FieldValue.delete(),
      'rejectedBy': FieldValue.arrayUnion([listenerId]),
    });
  }

  /// Seeker completes payment
  Future<void> markPaymentComplete(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': 'active',
    });
  }
  
  /// End session
  Future<void> endSession(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': 'completed',
    });
  }

  /// Cancel session
  Future<void> cancelSession(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': 'cancelled',
    });
  }
}
