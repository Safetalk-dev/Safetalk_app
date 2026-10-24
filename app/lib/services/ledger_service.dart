import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Single source of truth for listener earnings, pending payouts, and transaction history (A3.2 - D-06).
class LedgerService {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions? _functions;

  LedgerService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions;

  FirebaseFunctions get _functionsInstance =>
      _functions ?? FirebaseFunctions.instance;

  /// Helper to safely convert Firestore Timestamp or ISO string to DateTime
  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  /// Streams the listener's ledger document containing live balance and lifetime earnings
  Stream<Map<String, dynamic>?> streamLedger(String uid) {
    return _firestore.collection('ledgers').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      return {
        'pendingPayout': (data['pendingPayout'] is num)
            ? (data['pendingPayout'] as num).toDouble()
            : 0.0,
        'totalEarned': (data['totalEarned'] is num)
            ? (data['totalEarned'] as num).toDouble()
            : 0.0,
        'lastPayoutAt': _parseDate(data['lastPayoutAt']),
        'updatedAt': _parseDate(data['updatedAt']),
      };
    });
  }

  /// Fetches a one-time snapshot of the listener's ledger
  Future<Map<String, dynamic>?> getLedger(String uid) async {
    final doc = await _firestore.collection('ledgers').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    return {
      'pendingPayout': (data['pendingPayout'] is num)
          ? (data['pendingPayout'] as num).toDouble()
          : 0.0,
      'totalEarned': (data['totalEarned'] is num)
          ? (data['totalEarned'] as num).toDouble()
          : 0.0,
      'lastPayoutAt': _parseDate(data['lastPayoutAt']),
      'updatedAt': _parseDate(data['updatedAt']),
    };
  }

  /// Streams the audit trail of credits (sessions) and debits (payouts) in chronological descending order (A3.5)
  Stream<List<Map<String, dynamic>>> streamTransactions(String uid) {
    return _firestore
        .collection('ledgers')
        .doc(uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'type': data['type'] as String? ?? 'credit',
              'amount': (data['amount'] is num)
                  ? (data['amount'] as num).toDouble()
                  : 0.0,
              'description':
                  data['description'] as String? ?? 'Session Settlement',
              'timestamp': _parseDate(data['timestamp']),
              'sessionId': data['sessionId'] as String?,
              'durationMinutes': data['durationMinutes'] as int?,
              'status': data['status'] as String? ?? 'completed',
            };
          }).toList();
        });
  }

  /// Initiates a verified settlement of the current pending balance via Cloud Functions
  Future<Map<String, dynamic>> requestPayout(String uid) async {
    final callable = _functionsInstance.httpsCallable('processPayout');
    final result = await callable.call({'listenerUid': uid});
    return Map<String, dynamic>.from(result.data as Map);
  }
}
