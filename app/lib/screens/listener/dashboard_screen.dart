import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../widgets/haptic_touchable.dart';
import '../shared/history_screen.dart';
import 'messages_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

class ListenerDashboardScreen extends StatefulWidget {
  final bool isOnline;
  final ValueChanged<bool> onOnlineChanged;
  final VoidCallback onOpenRequests;

  const ListenerDashboardScreen({
    super.key,
    required this.isOnline,
    required this.onOnlineChanged,
    required this.onOpenRequests,
  });

  @override
  State<ListenerDashboardScreen> createState() => _ListenerDashboardScreenState();
}

class _ListenerDashboardScreenState extends State<ListenerDashboardScreen> {
  // Recent seekers connected
  final List<Map<String, dynamic>> _recentSeekers = [];
  String _displayName = '';
  int _sessionsCount = 0;
  String _rating = '5.00';

  @override
  void initState() {
    super.initState();
    _loadListenerData();
  }

  Future<void> _loadListenerData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await UserService().getUser(uid);
      if (user != null && mounted) {
        setState(() {
          _displayName = user.displayName;
          final stats = user.listenerData?.stats;
          if (stats != null) {
            _sessionsCount = stats.minutesListened ~/ 10;
            _rating = stats.rating.toStringAsFixed(2);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTherapist = SessionController().isTherapist;
    final brandColor = SafeTalkTheme.getListenerColor(isTherapist);
    final brandColorLight = SafeTalkTheme.getListenerColorLight(isTherapist);

    String greetingName = _displayName.isNotEmpty ? _displayName : AuthService().displayName;
    if (greetingName.isEmpty || greetingName == 'Anonymous') {
      greetingName = isTherapist ? 'Dr. Specialist' : 'Peer Listener';
    } else if (!greetingName.toLowerCase().startsWith('dr.') && !greetingName.toLowerCase().startsWith('listener')) {
      greetingName = isTherapist ? 'Dr. $greetingName' : 'Listener $greetingName';
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Beautiful Header / Welcome
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: brandColor.withValues(alpha: 0.15),
                child: Icon(
                  isTherapist ? Icons.psychology_rounded : Icons.face_retouching_natural_rounded,
                  color: brandColorLight,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      greetingName,
                      style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Online Availability Banner Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: SafeTalkTheme.glassCardDecoration.copyWith(
              border: Border.all(
                color: widget.isOnline ? brandColor.withValues(alpha: 0.4) : SafeTalkTheme.borderSage,
                width: 1.5,
              ),
              color: widget.isOnline ? brandColor.withValues(alpha: 0.04) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isOnline ? 'ONLINE & ACTIVE' : 'DESK GOING OFFLINE',
                        style: SafeTalkTheme.captionStyle(
                          color: widget.isOnline ? brandColorLight : SafeTalkTheme.textSecondary,
                        ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isOnline
                            ? 'Ready to accept incoming matching support requests.'
                            : 'Set status to online to start receiving connections.',
                        style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: widget.isOnline,
                  activeThumbColor: brandColorLight,
                  activeTrackColor: brandColor.withValues(alpha: 0.3),
                  inactiveThumbColor: SafeTalkTheme.textMuted,
                  inactiveTrackColor: SafeTalkTheme.bgMidnight,
                  onChanged: widget.onOnlineChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Stats Grid Rows
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '₹${_sessionsCount * 150}',
                  'Total Earnings',
                  Icons.payments_rounded,
                  brandColorLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '$_rating / 5',
                  'Satisfaction Rate',
                  Icons.star_rounded,
                  SafeTalkTheme.brandGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '$_sessionsCount',
                  'Sessions Completed',
                  Icons.forum_rounded,
                  SafeTalkTheme.brandSageLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '${(_sessionsCount * 0.25).toStringAsFixed(1)} hrs',
                  'Online Duration',
                  Icons.timer_outlined,
                  SafeTalkTheme.brandTerracotta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '0 Seekers',
                  'In Safe Circle',
                  Icons.favorite_rounded,
                  const Color(0xFFE084A0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '100%',
                  'Response Rate',
                  Icons.bolt_rounded,
                  SafeTalkTheme.brandGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 4. Weekly Session Activity Chart
          Text(
            'WEEKLY SESSION TRACKER',
            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: SafeTalkTheme.glassCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mon, May 22 - Sun, May 28',
                      style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                    ),
                    Text(
                      '12.4 Hours Total',
                      style: SafeTalkTheme.bodyStyle(color: brandColorLight, bold: true).copyWith(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Simple custom visual bar chart
                SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBarColumn('M', 0.3, brandColor),
                      _buildBarColumn('T', 0.5, brandColor),
                      _buildBarColumn('W', 0.8, brandColor),
                      _buildBarColumn('T', 0.2, brandColor),
                      _buildBarColumn('F', 0.9, brandColor),
                      _buildBarColumn('S', 0.6, brandColor),
                      _buildBarColumn('S', 0.4, brandColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 5. Active Match Alerts / Requests Direct Action
          if (widget.isOnline) ...[
            HapticTouchable(
              onTap: widget.onOpenRequests,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [brandColor.withValues(alpha: 0.4), SafeTalkTheme.bgMidnight.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: SafeTalkTheme.organicCardRadius,
                  border: Border.all(color: brandColor.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: SafeTalkTheme.brandTerracotta,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Incoming Request Radar Active',
                            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to open incoming match cards.',
                            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandSageLight),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: SafeTalkTheme.textSecondary, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // 6. Recent Seekers Chats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT SEEKERS & CHATS',
                style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              HapticTouchable(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ListenerMessagesScreen()),
                  );
                },
                child: Text(
                  'View All Chats',
                  style: SafeTalkTheme.captionStyle(color: brandColorLight).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentSeekers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: SafeTalkTheme.glassCardDecoration,
              child: Column(
                children: [
                  Icon(Icons.forum_outlined, color: brandColorLight, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    'No Recent Seekers',
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stay online to receive incoming matching support requests from seekers.',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentSeekers.length,
              itemBuilder: (context, index) {
                final seeker = _recentSeekers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: HapticTouchable(
                    onTap: () {
                      final threads = ChatController().listenerThreads;
                      final thread = threads.firstWhere(
                        (t) => t['name'] == seeker['name'],
                        orElse: () => {
                          'name': seeker['name'],
                          'status': 'Last active: ${seeker['lastActive']}',
                          'avatarColor': seeker['avatarColor'],
                          'online': false,
                          'unread': false,
                          'lastMessage': seeker['mood'],
                          'time': seeker['lastActive'],
                          'notes': '',
                          'messages': [
                            {'sender': 'user', 'text': 'Hello, is anyone there?'},
                            {'sender': 'listener', 'text': 'Hello. Yes, I am right here with you.'},
                          ]
                        },
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatHistoryTranscriptScreen(
                            session: thread,
                            isSeeker: false,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: SafeTalkTheme.glassCardDecoration,
                      child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: seeker['avatarColor'].withValues(alpha: 0.15),
                          child: Text(
                            seeker['name'][0],
                            style: SafeTalkTheme.bodyStyle(color: seeker['avatarColor'], bold: true).copyWith(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      seeker['name'],
                                      style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (seeker['isRegular']) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: brandColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'REGULAR',
                                        style: SafeTalkTheme.captionStyle(color: brandColorLight)
                                            .copyWith(fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Focus: ${seeker['mood']}',
                                style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          seeker['lastActive'],
                          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textMuted),
                        ),
                      ],
                    ),
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

  Widget _buildStatItem(String val, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SafeTalkTheme.glassCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            val,
            style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBarColumn(String day, double fraction, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            width: 14,
            decoration: BoxDecoration(
              color: SafeTalkTheme.borderSage,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: SafeTalkTheme.glowShadow(color, opacity: 0.3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textMuted).copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
