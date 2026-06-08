import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import 'explore_screen.dart';
import 'request_screen.dart';
import 'regulars_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import '../shared/voice_call_screen.dart';
import '../shared/video_call_screen.dart';
import '../shared/session_chat_screen.dart';
import '../shared/history_screen.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../widgets/haptic_touchable.dart';

class UserLayout extends StatefulWidget {
  final VoidCallback onLogout;

  const UserLayout({super.key, required this.onLogout});

  @override
  State<UserLayout> createState() => _UserLayoutState();
}

class _UserLayoutState extends State<UserLayout> {
  int _currentIndex = 0;
  bool _requestingListener = false;
  bool _showingNotifications = false;

  // Central Seeker State Variables
  String _username = "Mist Pebble #482";
  String _realName = "Logan";
  bool _isAnonymous = true;
  final List<double> _moodScores = [0.7, 0.4, 0.8, 0.3, 0.6, 0.75, 0.85];
  bool _dailyCheckInCompleted = false;

  // Centralized List of All Peer Listeners with their specialties & bio details
  final List<Map<String, dynamic>> _allListeners = [
    {
      'name': 'Amber R.',
      'rating': '4.9',
      'sessions': 8,
      'active': true,
      'avatarColor': SafeTalkTheme.brandSage,
      'specialties': ['Anxiety', 'Academic Stress', 'Relationships'],
      'bio': 'A compassionate ear. I believe in validation, slow containment, and holding a judgment-free harbor for your worries.',
      'latestNote': 'Last spoke on Fri: discussed boundary setting at school.',
    },
    {
      'name': 'Liam K.',
      'rating': '4.8',
      'sessions': 3,
      'active': true,
      'avatarColor': SafeTalkTheme.brandSageLight,
      'specialties': ['Career Burnout', 'LGBTQ+', 'Grief'],
      'bio': 'Certified peer counselor specializing in heavy work stress, career transitions, and life uncertainties. Let\'s talk.',
      'latestNote': 'Last spoke 1 week ago: work stress containment.',
    },
    {
      'name': 'Sophia M.',
      'rating': '5.0',
      'sessions': 14,
      'active': false,
      'avatarColor': SafeTalkTheme.brandTerracotta,
      'specialties': ['Mindfulness', 'Panic Attacks', 'Venting'],
      'bio': 'Focusing on calming somatic techniques, emotional release, and quiet deep listening. You are safe to drop your armor here.',
      'latestNote': 'Last spoke 2 weeks ago: somatic mindfulness guidance.',
    },
    {
      'name': 'Devon W.',
      'rating': '4.7',
      'sessions': 2,
      'active': true,
      'avatarColor': SafeTalkTheme.brandSage,
      'specialties': ['Family Dynamics', 'Depression Support'],
      'bio': 'A patient father and seasoned peer helper. Let\'s sort through the noise in your head together at your own pace.',
      'latestNote': 'Last spoke 1 month ago: discussed balancing parent schedules.',
    },
  ];

  // List of listeners marked as regulars
  final List<String> _regularListenerNames = ['Amber R.', 'Liam K.'];

  void _toggleRegularStatus(String name) {
    setState(() {
      if (_regularListenerNames.contains(name)) {
        _regularListenerNames.remove(name);
      } else {
        _regularListenerNames.add(name);
      }
    });
  }

  void _triggerRequestFlow(SessionType type) {
    SessionController().sessionType = type;
    setState(() {
      _requestingListener = true;
      _showingNotifications = false;
    });
  }

  void _cancelRequestFlow() {
    setState(() {
      _requestingListener = false;
    });
  }

  void _completeRequestFlow(String listenerName) {
    setState(() {
      _requestingListener = false;
    });
    
    final sessionType = SessionController().sessionType;
    Widget targetScreen;
    
    if (sessionType == SessionType.messages) {
      targetScreen = SessionChatScreen(
        partnerName: listenerName,
        isSeeker: true,
      );
    } else if (sessionType == SessionType.videoCall) {
      targetScreen = VideoCallScreen(
        partnerName: listenerName,
        isSeekerCaller: true,
      );
    } else {
      targetScreen = VoiceCallScreen(
        partnerName: listenerName,
        isSeekerCaller: true,
      );
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    ).then((_) {
      SessionController().sessionCompleted();
    });
  }

  void _handleMoodCheckIn(double score) {
    setState(() {
      // Map 1-10 score to 0.1-1.0 coordinate points on the Bezier graph
      final graphScore = (score / 10.0).clamp(0.1, 1.0);
      
      // Shift values and append to represent weekly rolling trend
      if (_moodScores.length >= 7) {
        _moodScores.removeAt(0);
      }
      _moodScores.add(graphScore);
      _dailyCheckInCompleted = true;
    });
  }

  Widget _buildBody() {
    if (_showingNotifications) {
      return UserNotificationScreen(onBack: () {
        setState(() => _showingNotifications = false);
      });
    }

    if (_requestingListener) {
      return RequestListenerScreen(
        onCancel: _cancelRequestFlow,
        onMatched: _completeRequestFlow,
      );
    }

    switch (_currentIndex) {
      case 0:
        return UserExploreScreen(
          username: _isAnonymous ? _username : _realName,
          checkInCompleted: _dailyCheckInCompleted,
          onMoodCheckedIn: _handleMoodCheckIn,
          onRequestListener: _triggerRequestFlow,
          onOpenListenerChat: (name) {
            final listener = _allListeners.firstWhere(
              (l) => l['name'] == name,
              orElse: () => <String, dynamic>{'active': false, 'avatarColor': SafeTalkTheme.brandSage},
            );
            final isActive = listener['active'] == true;

            if (isActive) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SessionChatScreen(
                    partnerName: name,
                    isSeeker: true,
                  ),
                ),
              );
            } else {
              final threads = ChatController().userThreads;
              final thread = threads.firstWhere(
                (t) => t['name'] == name,
                orElse: () => {
                  'name': name,
                  'status': 'Last session: ${listener['latestNote']?.split(':')?.first ?? 'Sun'}',
                  'avatarColor': listener['avatarColor'] ?? SafeTalkTheme.brandSage,
                  'online': false,
                  'unread': false,
                  'lastMessage': '',
                  'time': '1 week ago',
                  'notes': listener['latestNote'] ?? '',
                  'messages': [
                    {'sender': 'user', 'text': 'Hello, is anyone there?'},
                    {'sender': 'listener', 'text': 'Hello, yes I am here.'},
                  ]
                },
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatHistoryTranscriptScreen(
                    session: thread,
                    isSeeker: true,
                  ),
                ),
              );
            }
          },
          allListeners: _allListeners,
          regularListenerNames: _regularListenerNames,
          onToggleRegular: _toggleRegularStatus,
        );
      case 1:
        return UserRegularsScreen(
          onRequestInstant: _triggerRequestFlow,
          onMessageListener: (name) {
            final listener = _allListeners.firstWhere(
              (l) => l['name'] == name,
              orElse: () => <String, dynamic>{'active': false, 'avatarColor': SafeTalkTheme.brandSage},
            );
            final isActive = listener['active'] == true;

            if (isActive) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SessionChatScreen(
                    partnerName: name,
                    isSeeker: true,
                  ),
                ),
              );
            } else {
              final threads = ChatController().userThreads;
              final thread = threads.firstWhere(
                (t) => t['name'] == name,
                orElse: () => {
                  'name': name,
                  'status': 'Last session: ${listener['latestNote']?.split(':')?.first ?? 'Sun'}',
                  'avatarColor': listener['avatarColor'] ?? SafeTalkTheme.brandSage,
                  'online': false,
                  'unread': false,
                  'lastMessage': '',
                  'time': '1 week ago',
                  'notes': listener['latestNote'] ?? '',
                  'messages': [
                    {'sender': 'user', 'text': 'Hello, is anyone there?'},
                    {'sender': 'listener', 'text': 'Hello, yes I am here.'},
                  ]
                },
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatHistoryTranscriptScreen(
                    session: thread,
                    isSeeker: true,
                  ),
                ),
              );
            }
          },
          allListeners: _allListeners,
          regularListenerNames: _regularListenerNames,
          onToggleRegular: _toggleRegularStatus,
        );
      case 2:
        return const HistoryScreen(isSeeker: true);
      case 3:
        return UserProfileScreen(
          username: _isAnonymous ? _username : _realName,
          moodScores: _moodScores,
          onUsernameChanged: (newUsername) {
            setState(() {
              if (_isAnonymous) {
                _username = newUsername;
              } else {
                _realName = newUsername;
              }
            });
          },
          onLogout: widget.onLogout,
        );
      default:
        return UserExploreScreen(
          username: _isAnonymous ? _username : _realName,
          checkInCompleted: _dailyCheckInCompleted,
          onMoodCheckedIn: _handleMoodCheckIn,
          onRequestListener: _triggerRequestFlow,
          onOpenListenerChat: (n) {},
          allListeners: _allListeners,
          regularListenerNames: _regularListenerNames,
          onToggleRegular: _toggleRegularStatus,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Crucial for floating nav bar visual overlay
      appBar: AppBar(
        backgroundColor: SafeTalkTheme.bgMidnight,
        elevation: 0,
        centerTitle: false,
        title: InkWell(
          onTap: () {
            setState(() {
              _isAnonymous = !_isAnonymous;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isAnonymous
                      ? 'Confidential Anonymous Shield Activated'
                      : 'Public Mode Active: real identity shared',
                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight),
                ),
                backgroundColor: _isAnonymous ? SafeTalkTheme.brandTerracotta : SafeTalkTheme.brandSage,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          borderRadius: SafeTalkTheme.pillRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isAnonymous
                  ? SafeTalkTheme.brandTerracotta.withValues(alpha: 0.12)
                  : SafeTalkTheme.brandSage.withValues(alpha: 0.12),
              borderRadius: SafeTalkTheme.pillRadius,
              border: Border.all(
                color: _isAnonymous
                    ? SafeTalkTheme.brandTerracotta.withValues(alpha: 0.4)
                    : SafeTalkTheme.brandSage.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lens,
                  color: _isAnonymous ? SafeTalkTheme.brandTerracotta : SafeTalkTheme.brandSage,
                  size: 8,
                ),
                const SizedBox(width: 8),
                Text(
                  _isAnonymous ? 'Anonymous Mode' : 'Public Mode ($_realName)',
                  style: SafeTalkTheme.captionStyle(
                    color: _isAnonymous ? SafeTalkTheme.brandTerracotta : SafeTalkTheme.brandSage,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Icon(
                  _isAnonymous ? Icons.shield_outlined : Icons.lock_open_rounded,
                  color: _isAnonymous ? SafeTalkTheme.brandTerracotta : SafeTalkTheme.brandSage,
                  size: 13,
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Notifications Bell Icon
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  _showingNotifications ? Icons.notifications : Icons.notifications_none,
                  color: _showingNotifications ? SafeTalkTheme.brandTerracotta : SafeTalkTheme.textPrimary,
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: const BoxDecoration(
                      color: SafeTalkTheme.brandTerracotta,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              setState(() {
                _showingNotifications = !_showingNotifications;
                _requestingListener = false; // Close active matchmaking overlay
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: SafeTalkTheme.ambientBackground,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBody(),
        ),
      ),
      
      // Floating Custom Glassmorphic Nav Bar
      bottomNavigationBar: (_requestingListener || _showingNotifications)
          ? null // Hide navigation bar during matchmaking or notification view
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: SafeTalkTheme.cardBg.withValues(alpha: 0.92),
                  borderRadius: SafeTalkTheme.pillRadius,
                  border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
                  boxShadow: SafeTalkTheme.glowShadow(Colors.black, opacity: 0.4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.compass_calibration_outlined, Icons.explore, 'Explore'),
                      _buildNavItem(1, Icons.favorite_outline, Icons.favorite, 'Circle'),
                      _buildNavItem(2, Icons.history_rounded, Icons.history_rounded, 'History'),
                      _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    final activeColor = SafeTalkTheme.brandTerracotta;

    return HapticTouchable(
      onTap: () => setState(() {
        _currentIndex = index;
        _showingNotifications = false;
        _requestingListener = false;
      }),
      pressedScale: 0.95,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: SafeTalkTheme.pillRadius,
            ),
            child: Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? activeColor : SafeTalkTheme.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: SafeTalkTheme.captionStyle(
              color: isSelected ? activeColor : SafeTalkTheme.textSecondary,
            ).copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
