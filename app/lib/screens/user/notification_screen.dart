import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class UserNotificationScreen extends StatefulWidget {
  final VoidCallback onBack;

  const UserNotificationScreen({super.key, required this.onBack});

  @override
  State<UserNotificationScreen> createState() => _UserNotificationScreenState();
}

class _UserNotificationScreenState extends State<UserNotificationScreen> {
  late List<Map<String, dynamic>> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [];
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
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

  void _removeNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Back button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: SafeTalkTheme.textPrimary, size: 20),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              Text(
                'Quiet Updates',
                style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 28),
              ),
              const Spacer(),
              if (_notifications.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear_all_rounded, color: SafeTalkTheme.brandTerracotta, size: 16),
                  label: Text(
                    'Clear All',
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandTerracotta, bold: true).copyWith(fontSize: 13.5),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 48.0),
            child: Text(
              'Discreet notifications regarding your matches and summaries.',
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
            ),
          ),

          const SizedBox(height: 32),

          // List of notifications / Calming Empty State
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.spa_outlined,
                            color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.6),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "You're all caught up",
                          style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "No new quiet updates right now.\nTake a deep breath and have a mindful day.",
                          textAlign: TextAlign.center,
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary).copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      // Use unique key combination of title + time to prevent item reuse issues
                      final uniqueKey = ValueKey(notif['title'] + notif['time']);

                      return Padding(
                        key: uniqueKey,
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Dismissible(
                          key: uniqueKey,
                          direction: DismissDirection.horizontal,
                          onDismissed: (direction) {
                            _removeNotification(index);
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
                          },
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            decoration: BoxDecoration(
                              color: SafeTalkTheme.brandGold.withValues(alpha: 0.15),
                              borderRadius: SafeTalkTheme.organicCardRadius,
                            ),
                            child: const Icon(Icons.delete_sweep_rounded, color: SafeTalkTheme.brandGold),
                          ),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: SafeTalkTheme.brandGold.withValues(alpha: 0.15),
                              borderRadius: SafeTalkTheme.organicCardRadius,
                            ),
                            child: const Icon(Icons.delete_sweep_rounded, color: SafeTalkTheme.brandGold),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                              border: Border.all(
                                color: notif['unread']
                                    ? SafeTalkTheme.brandTerracotta.withValues(alpha: 0.3)
                                    : SafeTalkTheme.borderSage,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Icon indicator
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: notif['color'].withValues(alpha: 0.12),
                                  child: Icon(notif['icon'], color: notif['color'], size: 20),
                                ),
                                const SizedBox(width: 16),
                                
                                // Core message
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif['title'],
                                              style: SafeTalkTheme.bodyStyle(
                                                color: SafeTalkTheme.textPrimary,
                                                bold: true,
                                              ).copyWith(fontSize: 15),
                                            ),
                                          ),
                                          Text(
                                            notif['time'],
                                            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                                          ),
                                          const SizedBox(width: 10),
                                          // Individual X Close Button
                                          GestureDetector(
                                            onTap: () => _removeNotification(index),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 16,
                                              color: SafeTalkTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        notif['desc'],
                                        style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary)
                                            .copyWith(fontSize: 13, height: 1.4),
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
  }
}
