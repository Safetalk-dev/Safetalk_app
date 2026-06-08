import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import 'listener_detail_screen.dart';
import '../../controllers/session_controller.dart';
import '../../widgets/haptic_touchable.dart';

class UserRegularsScreen extends StatelessWidget {
  final Function(SessionType type) onRequestInstant;
  final Function(String name) onMessageListener;
  final List<Map<String, dynamic>> allListeners;
  final List<String> regularListenerNames;
  final Function(String name) onToggleRegular;

  const UserRegularsScreen({
    super.key,
    required this.onRequestInstant,
    required this.onMessageListener,
    required this.allListeners,
    required this.regularListenerNames,
    required this.onToggleRegular,
  });

  void _showSessionSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
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
                'Start Circle Session',
                style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Select your preferred connection medium. All sessions are secure, private, and encrypted.',
                style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildSessionOptionCard(
                context,
                type: SessionType.messages,
                title: 'Messages Session',
                duration: '10 min duration',
                price: '₹150 / session',
                icon: Icons.chat_bubble_outline_rounded,
                color: SafeTalkTheme.brandTerracotta,
              ),
              const SizedBox(height: 12),
              _buildSessionOptionCard(
                context,
                type: SessionType.voiceCall,
                title: 'Voice Call Session',
                duration: '10 min duration',
                price: '₹150 / session',
                icon: Icons.phone_outlined,
                color: SafeTalkTheme.brandSage,
              ),
              const SizedBox(height: 12),
              _buildSessionOptionCard(
                context,
                type: SessionType.videoCall,
                title: 'Video Call Session',
                duration: '7 min duration',
                price: '₹150 / session',
                icon: Icons.videocam_outlined,
                color: SafeTalkTheme.brandGold,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionOptionCard(
    BuildContext context, {
    required SessionType type,
    required String title,
    required String duration,
    required String price,
    required IconData icon,
    required Color color,
  }) {
    return HapticTouchable(
      onTap: () {
        Navigator.pop(context);
        onRequestInstant(type);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: SafeTalkTheme.glassCardDecoration.copyWith(
          border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    duration,
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: SafeTalkTheme.bodyStyle(color: color, bold: true).copyWith(fontSize: 15),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: SafeTalkTheme.textMuted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final circleList = allListeners.where((l) => regularListenerNames.contains(l['name'])).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header titles
          Text(
            'My Safe Circle',
            style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 28),
          ),
          const SizedBox(height: 6),
          Text(
            'These supportive ears have held space for you in past sessions.',
            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
          ),
          
          const SizedBox(height: 28),

          // Grid/List of regular helpers
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: circleList.length,
              itemBuilder: (context, index) {
                final regular = circleList[index];
                return Padding(
                  key: ValueKey(regular['name']),
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListenerDetailScreen(
                            listener: regular,
                            isRegular: regularListenerNames.contains(regular['name']),
                            onToggleRegular: onToggleRegular,
                            onMessage: () {
                              Navigator.pop(context);
                              onMessageListener(regular['name']);
                            },
                            onConnectNow: () {
                              Navigator.pop(context);
                              _showSessionSelectionSheet(context);
                            },
                            onBack: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                        border: Border.all(
                          color: (regular['active'] ?? false)
                              ? SafeTalkTheme.brandTerracotta.withValues(alpha: 0.3)
                              : SafeTalkTheme.borderSage,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header info
                          Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: regular['avatarColor'].withValues(alpha: 0.2),
                                    child: Text(
                                      regular['name'][0],
                                      style: SafeTalkTheme.headingStyle(color: regular['avatarColor']),
                                    ),
                                  ),
                                  if (regular['active'] ?? false)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        height: 11,
                                        width: 11,
                                        decoration: BoxDecoration(
                                          color: SafeTalkTheme.brandSage,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: SafeTalkTheme.bgMidnight, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              
                              const SizedBox(width: 16),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      regular['name'],
                                      style: SafeTalkTheme.bodyStyle(
                                        color: SafeTalkTheme.textPrimary,
                                        bold: true,
                                      ).copyWith(fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '${regular['sessions']} sessions',
                                          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandSageLight),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.star, color: SafeTalkTheme.brandGold, size: 12),
                                        const SizedBox(width: 2),
                                        Text(
                                          regular['rating'],
                                          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandGold)
                                              .copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Recent note context container
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: SafeTalkTheme.bgMidnight,
                              borderRadius: SafeTalkTheme.standardRadius,
                              border: Border.all(color: SafeTalkTheme.borderSage, width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.history_edu_outlined, color: SafeTalkTheme.textSecondary, size: 16),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    regular['latestNote'],
                                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Fast actions
                          // Fast actions
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: (regular['active'] ?? false) ? () => _showSessionSelectionSheet(context) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SafeTalkTheme.brandTerracotta,
                                foregroundColor: SafeTalkTheme.bgMidnight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: SafeTalkTheme.organicCardRadius,
                                ),
                                elevation: 2,
                                disabledBackgroundColor: SafeTalkTheme.cardBg,
                                disabledForegroundColor: SafeTalkTheme.textMuted,
                              ),
                              child: Text(
                                (regular['active'] ?? false) ? 'Request Now' : 'Offline',
                                style: SafeTalkTheme.bodyStyle(
                                  color: (regular['active'] ?? false) ? SafeTalkTheme.bgMidnight : SafeTalkTheme.textMuted,
                                  bold: true,
                                ),
                              ),
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
