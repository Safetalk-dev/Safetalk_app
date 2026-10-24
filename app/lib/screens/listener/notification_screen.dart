import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import '../../theme/tokens.dart';

class ListenerNotificationScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ListenerNotificationScreen({super.key, required this.onBack});

  @override
  State<ListenerNotificationScreen> createState() =>
      _ListenerNotificationScreenState();
}

class _ListenerNotificationScreenState
    extends State<ListenerNotificationScreen> {
  final NotificationService _notificationService = NotificationService();

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'match_request':
        return Icons.person_pin_circle_outlined;
      case 'payout':
        return Icons.account_balance_wallet_outlined;
      case 'session_active':
        return Icons.mark_chat_read_outlined;
      case 'session_completed':
        return Icons.task_alt_rounded;
      default:
        return Icons.spa_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'payout':
        return SafeTalkTheme.brandGold;
      case 'match_failed':
        return Colors.redAccent;
      default:
        return SafeTalkTheme.brandSage;
    }
  }

  void _clearAll(String uid) {
    _notificationService.clearAll(uid);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All duty alerts cleared.',
          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight),
        ),
        backgroundColor: SafeTalkTheme.textPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeNotification(String uid, String notifId) {
    _notificationService.deleteNotification(uid, notifId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Alert cleared',
          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight),
        ),
        backgroundColor: SafeTalkTheme.textPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: uid.isNotEmpty
          ? _notificationService.streamNotifications(uid)
          : Stream.value([]),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header titles
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: SafeTalkTheme.textPrimary,
                      size: 20,
                    ),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Duty Alerts',
                    style: SafeTalkTheme.displayStyle(
                      color: SafeTalkTheme.textPrimary,
                    ).copyWith(fontSize: 28),
                  ),
                  const Spacer(),
                  if (notifications.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _clearAll(uid),
                      icon: const Icon(
                        Icons.clear_all_rounded,
                        color: SafeTalkTheme.brandSage,
                        size: 16,
                      ),
                      label: Text(
                        'Clear All',
                        style: SafeTalkTheme.bodyStyle(
                          color: SafeTalkTheme.brandSage,
                          bold: true,
                        ).copyWith(fontSize: 13.5),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 48.0),
                child: Text(
                  'Discreet announcements regarding shift surge and administrative feedback.',
                  style: SafeTalkTheme.bodyStyle(
                    color: SafeTalkTheme.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Notifications List / Calm Empty State
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: SafeTalkTheme.brandSage.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.spa_outlined,
                                color: SafeTalkTheme.brandSage.withValues(
                                  alpha: 0.6,
                                ),
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Duty Desk is Clear",
                              style: SafeTalkTheme.headingStyle(
                                color: SafeTalkTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "No active alerts or updates currently.\nThank you for holding space for those in need.",
                              textAlign: TextAlign.center,
                              style: SafeTalkTheme.bodyStyle(
                                color: SafeTalkTheme.textSecondary,
                              ).copyWith(height: 1.4),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          final notifId = notif['id'] as String;
                          final uniqueKey = ValueKey(notifId);
                          final type = notif['type'] as String? ?? 'system';
                          final color = _getColorForType(type);
                          final icon = _getIconForType(type);
                          final isUnread = !(notif['read'] as bool? ?? false);
                          final timeStr = _formatTime(
                            notif['createdAt'] as DateTime,
                          );

                          return Padding(
                            key: uniqueKey,
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Dismissible(
                              key: uniqueKey,
                              direction: DismissDirection.horizontal,
                              onDismissed: (direction) {
                                _removeNotification(uid, notifId);
                              },
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                decoration: BoxDecoration(
                                  color: SafeTalkTheme.brandGold.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: SafeTalkTheme.organicCardRadius,
                                ),
                                child: const Icon(
                                  Icons.delete_sweep_rounded,
                                  color: SafeTalkTheme.brandGold,
                                ),
                              ),
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: SafeTalkTheme.brandGold.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: SafeTalkTheme.organicCardRadius,
                                ),
                                child: const Icon(
                                  Icons.delete_sweep_rounded,
                                  color: SafeTalkTheme.brandGold,
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: SafeTalkTheme.glassCardDecoration
                                    .copyWith(
                                      border: Border.all(
                                        color: isUnread
                                            ? SafeTalkTheme.brandSage
                                                  .withValues(alpha: 0.3)
                                            : SafeTalkTheme.borderSage,
                                        width: 1.5,
                                      ),
                                    ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: color.withValues(
                                        alpha: 0.12,
                                      ),
                                      child: Icon(icon, color: color, size: 20),
                                    ),
                                    const SizedBox(width: 16),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif['title'] as String? ??
                                                      'Alert',
                                                  style:
                                                      SafeTalkTheme.bodyStyle(
                                                        color: SafeTalkTheme
                                                            .textPrimary,
                                                        bold: true,
                                                      ).copyWith(fontSize: 15),
                                                ),
                                              ),
                                              Text(
                                                timeStr,
                                                style:
                                                    SafeTalkTheme.captionStyle(
                                                      color: SafeTalkTheme
                                                          .textSecondary,
                                                    ),
                                              ),
                                              const SizedBox(width: 10),
                                              // Individual X Close Button
                                              GestureDetector(
                                                onTap: () =>
                                                    _removeNotification(
                                                      uid,
                                                      notifId,
                                                    ),
                                                child: const Icon(
                                                  Icons.close_rounded,
                                                  size: 16,
                                                  color:
                                                      SafeTalkTheme.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            notif['body'] as String? ?? '',
                                            style:
                                                SafeTalkTheme.bodyStyle(
                                                  color: SafeTalkTheme
                                                      .textSecondary,
                                                ).copyWith(
                                                  fontSize: 13,
                                                  height: 1.4,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
