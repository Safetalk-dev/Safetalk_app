import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:app/services/ledger_service.dart';

void main() {
  group('LedgerService (A3.2 - D-06)', () {
    late FakeFirebaseFirestore fakeFirestore;
    late LedgerService ledgerService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      ledgerService = LedgerService(firestore: fakeFirestore);
    });

    test('getLedger returns null for non-existent ledger', () async {
      final ledger = await ledgerService.getLedger('non_existent_uid');
      expect(ledger, isNull);
    });

    test('getLedger and streamLedger return parsed balance and earnings', () async {
      const uid = 'listener_123';
      final now = DateTime.now();

      await fakeFirestore.collection('ledgers').doc(uid).set({
        'pendingPayout': 50.0,
        'totalEarned': 250.0,
        'lastPayoutAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      final snapshot = await ledgerService.getLedger(uid);
      expect(snapshot, isNotNull);
      expect(snapshot!['pendingPayout'], 50.0);
      expect(snapshot['totalEarned'], 250.0);
      expect(snapshot['lastPayoutAt'], isNotNull);

      // Verify stream
      final streamed = await ledgerService.streamLedger(uid).first;
      expect(streamed, isNotNull);
      expect(streamed!['pendingPayout'], 50.0);
      expect(streamed['totalEarned'], 250.0);
    });

    test('streamTransactions returns ordered list of credits and debits (A3.5)', () async {
      const uid = 'listener_tx_test';
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(minutes: 10));

      final ledgerRef = fakeFirestore.collection('ledgers').doc(uid);
      await ledgerRef.set({'pendingPayout': 50.0, 'totalEarned': 50.0});

      await ledgerRef.collection('transactions').doc('tx_1').set({
        'type': 'credit',
        'amount': 50.0,
        'description': 'Peer Session (10 mins)',
        'sessionId': 'session_abc',
        'durationMinutes': 10,
        'timestamp': earlier,
        'status': 'completed',
      });

      await ledgerRef.collection('transactions').doc('tx_2').set({
        'type': 'debit',
        'amount': -50.0,
        'description': 'Bank Transfer Payout',
        'payoutId': 'payout_xyz',
        'timestamp': now,
        'status': 'completed',
      });

      final txList = await ledgerService.streamTransactions(uid).first;
      expect(txList.length, 2);

      // Descending order: tx_2 is newer than tx_1
      expect(txList[0]['id'], 'tx_2');
      expect(txList[0]['type'], 'debit');
      expect(txList[0]['amount'], -50.0);

      expect(txList[1]['id'], 'tx_1');
      expect(txList[1]['type'], 'credit');
      expect(txList[1]['amount'], 50.0);
      expect(txList[1]['durationMinutes'], 10);
    });
  });
}
