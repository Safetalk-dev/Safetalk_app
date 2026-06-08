import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../controllers/session_controller.dart';

class ListenerTransactionsScreen extends StatefulWidget {
  const ListenerTransactionsScreen({super.key});

  @override
  State<ListenerTransactionsScreen> createState() => _ListenerTransactionsScreenState();
}

class _ListenerTransactionsScreenState extends State<ListenerTransactionsScreen> {

  // Mock list of transactions
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'TXN-984210',
      'seekerName': 'Pine Pebble #107',
      'type': 'Voice Call Support',
      'date': 'May 28, 2026 • 3:14 PM',
      'amount': 150.0,
      'status': 'Settled',
      'isPremium': false,
    },
    {
      'id': 'TXN-983104',
      'seekerName': 'Mist Pebble #44',
      'type': 'Secure Chat Support',
      'date': 'May 27, 2026 • 9:45 AM',
      'amount': 150.0,
      'status': 'Settled',
      'isPremium': false,
    },
    {
      'id': 'TXN-981892',
      'seekerName': 'River Stone #82',
      'type': 'Video Call Consultation',
      'date': 'May 26, 2026 • 6:18 PM',
      'amount': 499.0,
      'status': 'Settled',
      'isPremium': true,
    },
    {
      'id': 'TXN-979920',
      'seekerName': 'Fern Leaf #29',
      'type': 'Voice Call Support',
      'date': 'May 24, 2026 • 11:20 AM',
      'amount': 150.0,
      'status': 'Settled',
      'isPremium': false,
    }
  ];

  void _triggerWithdrawalSimulation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isTherapist = SessionController().isTherapist;
        final brandColor = SafeTalkTheme.getListenerColor(isTherapist);
        final brandColorLight = SafeTalkTheme.getListenerColorLight(isTherapist);

        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                        color: SafeTalkTheme.textSecondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Withdrawal Request',
                    style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Transfer your verified outstanding earnings directly to your connected bank account.',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Outstanding amount card
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
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
                        ),
                        Text(
                          '₹4,250.00',
                          style: SafeTalkTheme.bodyStyle(color: brandColorLight, bold: true).copyWith(fontSize: 16),
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
                        Icon(Icons.account_balance_rounded, color: brandColorLight, size: 20),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Axis Bank India Ltd.',
                                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'A/C Number: •••• 4892  •  IFSC: UTIB0000281',
                                style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SafeTalkTheme.brandSage.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PRIMARY',
                            style: TextStyle(color: SafeTalkTheme.brandSage, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Transfer button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Payout successfully initiated! ₹4,250 will be settled in your Axis Bank account within 24 hours.',
                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                            ),
                            backgroundColor: SafeTalkTheme.brandSage,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor: SafeTalkTheme.bgMidnight,
                        shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.organicCardRadius),
                        elevation: 0,
                      ),
                      child: Text(
                        'Confirm & Transfer to Bank',
                        style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel Request',
                      style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandTerracotta, bold: true),
                    ),
                  )
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Transaction Portal Summary
          Text(
            'TRANSACTION ACCOUNT PORTAL',
            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: SafeTalkTheme.glassCardDecoration.copyWith(
              border: Border.all(color: brandColor.withValues(alpha: 0.3), width: 1.5),
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
                          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹4,250.00',
                          style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 28),
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
                          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹24,850.00',
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Completed Payouts',
                          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹20,600.00',
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandSageLight, bold: true),
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
                    onPressed: _triggerWithdrawalSimulation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      foregroundColor: SafeTalkTheme.bgMidnight,
                      shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.organicCardRadius),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.outbound_rounded, size: 16),
                    label: Text(
                      'Withdraw Outstanding Earnings',
                      style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true).copyWith(fontSize: 13),
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
            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
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
                  child: Icon(Icons.account_balance_rounded, color: brandColorLight, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Axis Bank India Ltd.',
                        style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A/C Number: •••• 4892  •  IFSC: UTIB0000281',
                        style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 3. Transactions List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT TRANSACTIONS LOGS',
                style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const Icon(Icons.filter_list_rounded, color: SafeTalkTheme.textSecondary, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final txn = _transactions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: SafeTalkTheme.glassCardDecoration,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: txn['isPremium']
                            ? SafeTalkTheme.brandGold.withValues(alpha: 0.15)
                            : brandColor.withValues(alpha: 0.15),
                        child: Icon(
                          txn['isPremium'] ? Icons.videocam_rounded : Icons.phone_rounded,
                          color: txn['isPremium'] ? SafeTalkTheme.brandGold : brandColorLight,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              txn['seekerName'],
                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${txn['type']} • ${txn['id']}',
                              style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              txn['date'],
                              style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textMuted).copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+₹${txn['amount'].toStringAsFixed(0)}',
                            style: SafeTalkTheme.bodyStyle(
                              color: txn['isPremium'] ? SafeTalkTheme.brandGold : brandColorLight,
                              bold: true,
                            ).copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SafeTalkTheme.brandSage.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SETTLED',
                              style: TextStyle(color: SafeTalkTheme.brandSage, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
