import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../controllers/session_controller.dart';
import '../../services/ledger_service.dart';

class ListenerTransactionsScreen extends StatefulWidget {
  const ListenerTransactionsScreen({super.key});

  @override
  State<ListenerTransactionsScreen> createState() =>
      _ListenerTransactionsScreenState();
}

class _ListenerTransactionsScreenState
    extends State<ListenerTransactionsScreen> {
  final LedgerService _ledgerService = LedgerService();
  bool _isWithdrawing = false;

  void _triggerWithdrawal(double pendingPayout) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isTherapist = SessionController().isTherapist;
        final brandColor = SafeTalkTheme.getListenerColor(isTherapist);
        final brandColorLight = SafeTalkTheme.getListenerColorLight(
          isTherapist,
        );

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final canWithdraw = pendingPayout > 0 && !_isWithdrawing;

            return Container(
              decoration: BoxDecoration(
                color: SafeTalkTheme.cardBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: SafeTalkTheme.textSecondary.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Withdrawal Request',
                    style: SafeTalkTheme.headingStyle(
                      color: SafeTalkTheme.textPrimary,
                    ).copyWith(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Transfer your verified outstanding earnings directly to your connected bank account.',
                    style: SafeTalkTheme.captionStyle(
                      color: SafeTalkTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Outstanding amount card (A3.2 & A3.3)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SafeTalkTheme.bgMidnight,
                      borderRadius: SafeTalkTheme.standardRadius,
                      border: Border.all(color: SafeTalkTheme.borderSage),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transferable Amount',
                          style: SafeTalkTheme.bodyStyle(
                            color: SafeTalkTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '₹${pendingPayout.toStringAsFixed(2)}',
                          style: SafeTalkTheme.bodyStyle(
                            color: brandColorLight,
                            bold: true,
                          ).copyWith(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Destination Bank Account Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: SafeTalkTheme.glassCardDecoration,
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_rounded,
                          color: brandColorLight,
                          size: 20,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Axis Bank India Ltd.',
                                style: SafeTalkTheme.bodyStyle(
                                  color: SafeTalkTheme.textPrimary,
                                  bold: true,
                                ).copyWith(fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'A/C Number: •••• 4892  •  IFSC: UTIB0000281',
                                style: SafeTalkTheme.captionStyle(
                                  color: SafeTalkTheme.textSecondary,
                                ).copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: SafeTalkTheme.brandSage.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PRIMARY',
                            style: TextStyle(
                              color: SafeTalkTheme.brandSage,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Transfer button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: canWithdraw
                          ? () async {
                              setSheetState(() => _isWithdrawing = true);
                              try {
                                final uid =
                                    SessionController().firebaseUid ?? '';
                                final result = await _ledgerService
                                    .requestPayout(uid);
                                final message =
                                    result['message'] ??
                                    'Payout successfully processed!';
                                if (!mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      message.toString(),
                                      style: SafeTalkTheme.bodyStyle(
                                        color: SafeTalkTheme.bgMidnight,
                                        bold: true,
                                      ),
                                    ),
                                    backgroundColor: SafeTalkTheme.brandSage,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              } finally {
                                if (mounted) {
                                  setSheetState(() => _isWithdrawing = false);
                                }
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor: SafeTalkTheme.bgMidnight,
                        disabledBackgroundColor: SafeTalkTheme.borderSage,
                        shape: RoundedRectangleBorder(
                          borderRadius: SafeTalkTheme.organicCardRadius,
                        ),
                        elevation: 0,
                      ),
                      child: _isWithdrawing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: SafeTalkTheme.bgMidnight,
                              ),
                            )
                          : Text(
                              pendingPayout > 0
                                  ? 'Confirm & Transfer to Bank'
                                  : 'No Pending Balance to Withdraw',
                              style: SafeTalkTheme.bodyStyle(
                                color: SafeTalkTheme.bgMidnight,
                                bold: true,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isWithdrawing
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: Text(
                      'Cancel Request',
                      style: SafeTalkTheme.bodyStyle(
                        color: SafeTalkTheme.brandTerracotta,
                        bold: true,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTherapist = SessionController().isTherapist;
    final brandColor = SafeTalkTheme.getListenerColor(isTherapist);
    final brandColorLight = SafeTalkTheme.getListenerColorLight(isTherapist);
    final uid = SessionController().firebaseUid ?? '';

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _ledgerService.streamLedger(uid),
      builder: (context, ledgerSnapshot) {
        final ledger = ledgerSnapshot.data;
        final double pendingPayout = ledger?['pendingPayout'] ?? 0.0;
        final double totalEarned = ledger?['totalEarned'] ?? 0.0;
        final double completedPayouts = (totalEarned - pendingPayout).clamp(
          0.0,
          double.infinity,
        );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Transaction Portal Summary (A3.2)
              Text(
                'TRANSACTION ACCOUNT PORTAL',
                style: SafeTalkTheme.captionStyle(
                  color: SafeTalkTheme.textSecondary,
                ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                  border: Border.all(
                    color: brandColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verified Outstanding',
                              style: SafeTalkTheme.captionStyle(
                                color: SafeTalkTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${pendingPayout.toStringAsFixed(2)}',
                              style: SafeTalkTheme.displayStyle(
                                color: SafeTalkTheme.textPrimary,
                              ).copyWith(fontSize: 28),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          color: brandColorLight,
                          size: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: SafeTalkTheme.borderSage, height: 1),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lifetime Earnings',
                              style: SafeTalkTheme.captionStyle(
                                color: SafeTalkTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${totalEarned.toStringAsFixed(2)}',
                              style: SafeTalkTheme.bodyStyle(
                                color: SafeTalkTheme.textPrimary,
                                bold: true,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Completed Payouts',
                              style: SafeTalkTheme.captionStyle(
                                color: SafeTalkTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${completedPayouts.toStringAsFixed(2)}',
                              style: SafeTalkTheme.bodyStyle(
                                color: SafeTalkTheme.brandSageLight,
                                bold: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Payout Trigger
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _triggerWithdrawal(pendingPayout),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandColor,
                          foregroundColor: SafeTalkTheme.bgMidnight,
                          shape: RoundedRectangleBorder(
                            borderRadius: SafeTalkTheme.organicCardRadius,
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.outbound_rounded, size: 16),
                        label: Text(
                          'Withdraw Outstanding Earnings',
                          style: SafeTalkTheme.bodyStyle(
                            color: SafeTalkTheme.bgMidnight,
                            bold: true,
                          ).copyWith(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 2. Connected Settlement Bank Card
              Text(
                'CONNECTED SETTLEMENT ACCOUNT',
                style: SafeTalkTheme.captionStyle(
                  color: SafeTalkTheme.textSecondary,
                ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: SafeTalkTheme.glassCardDecoration,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: brandColorLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Axis Bank India Ltd.',
                            style: SafeTalkTheme.bodyStyle(
                              color: SafeTalkTheme.textPrimary,
                              bold: true,
                            ).copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A/C Number: •••• 4892  •  IFSC: UTIB0000281',
                            style: SafeTalkTheme.captionStyle(
                              color: SafeTalkTheme.textSecondary,
                            ).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 3. Transactions List (A3.5 - Live Stream from Firestore)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT TRANSACTIONS LOGS',
                    style: SafeTalkTheme.captionStyle(
                      color: SafeTalkTheme.textSecondary,
                    ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const Icon(
                    Icons.filter_list_rounded,
                    color: SafeTalkTheme.textSecondary,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _ledgerService.streamTransactions(uid),
                builder: (context, txSnapshot) {
                  final transactions = txSnapshot.data ?? [];

                  if (transactions.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: SafeTalkTheme.glassCardDecoration,
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color: brandColorLight,
                            size: 36,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No Transactions Yet',
                            style: SafeTalkTheme.bodyStyle(
                              color: SafeTalkTheme.textPrimary,
                              bold: true,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'When you complete counseling sessions, your session payments and settlements will appear here.',
                            style: SafeTalkTheme.captionStyle(
                              color: SafeTalkTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final txn = transactions[index];
                      final isCredit = txn['type'] == 'credit';
                      final double amount = txn['amount'] ?? 0.0;
                      final DateTime? dt = txn['timestamp'] as DateTime?;
                      final String dateStr = dt != null
                          ? '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
                          : 'Recent';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: SafeTalkTheme.glassCardDecoration,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isCredit
                                    ? brandColor.withValues(alpha: 0.15)
                                    : SafeTalkTheme.brandTerracotta.withValues(
                                        alpha: 0.15,
                                      ),
                                child: Icon(
                                  isCredit
                                      ? Icons.add_circle_outline_rounded
                                      : Icons.outbound_rounded,
                                  color: isCredit
                                      ? brandColorLight
                                      : SafeTalkTheme.brandTerracotta,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      txn['description'] ??
                                          (isCredit
                                              ? 'Peer Session Earnings'
                                              : 'Bank Settlement'),
                                      style: SafeTalkTheme.bodyStyle(
                                        color: SafeTalkTheme.textPrimary,
                                        bold: true,
                                      ).copyWith(fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ID: ${txn['id']}',
                                      style: SafeTalkTheme.captionStyle(
                                        color: SafeTalkTheme.textSecondary,
                                      ).copyWith(fontSize: 11),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateStr,
                                      style: SafeTalkTheme.captionStyle(
                                        color: SafeTalkTheme.textMuted,
                                      ).copyWith(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isCredit
                                        ? '+₹${amount.toStringAsFixed(2)}'
                                        : '-₹${amount.abs().toStringAsFixed(2)}',
                                    style: SafeTalkTheme.bodyStyle(
                                      color: isCredit
                                          ? brandColorLight
                                          : SafeTalkTheme.brandTerracotta,
                                      bold: true,
                                    ).copyWith(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SafeTalkTheme.brandSage.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      (txn['status'] ?? 'SETTLED')
                                          .toString()
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: SafeTalkTheme.brandSage,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
