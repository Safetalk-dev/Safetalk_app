import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import '../../theme/tokens.dart';

class UserNotificationScreen extends StatefulWidget {
  final VoidCallback onBack;

  const UserNotificationScreen({super.key, required this.onBack});

  @override
  State<UserNotificationScreen> createState() => _UserNotificationScreenState();
}

class _UserNotificationScreenState extends State<UserNotificationScreen> {
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
      case 'payment_pending':
        return Icons.credit_card_outlined;
      case 'session_active':
        return Icons.chat_bubble_outline_rounded;
      case 'session_completed':
        return Icons.favorite_border_rounded;
      case 'match_failed':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'match_failed':
        return Colors.redAccent;
      case 'payment_pending':
        return SafeTalkTheme.brandGold;
      default:
        return SafeTalkTheme.brandTerracotta;
    }
  }

  void _clearAll(String uid) {
    _notificationService.clearAll(uid);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All notifications cleared.',
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
          'Notification cleared',
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
              // Header with Back button
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
                    'Quiet Updates',
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
                        color: SafeTalkTheme.brandTerracotta,
                        size: 16,
                      ),
                      label: Text(
                        'Clear All',
                        style: SafeTalkTheme.bodyStyle(
                          color: SafeTalkTheme.brandTerracotta,
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
                  'Discreet notifications regarding your matches and summaries.',
                  style: SafeTalkTheme.bodyStyle(
                    color: SafeTalkTheme.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // List of notifications / Calming Empty State
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: SafeTalkTheme.brandTerracotta.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_off_outlined,
                                color: SafeTalkTheme.brandTerracotta.withValues(
                                  alpha: 0.6,
                                ),
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Space is Quiet",
                              style: SafeTalkTheme.headingStyle(
                                color: SafeTalkTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "No active notifications or matching alerts.\nYour safe space is resting peacefully.",
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
                                            ? SafeTalkTheme.brandTerracotta
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
                                                      'Notification',
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
