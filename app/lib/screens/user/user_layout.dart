import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import 'explore_screen.dart';
import 'request_screen.dart';
import 'regulars_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import '../shared/session_chat_screen.dart';
import '../shared/history_screen.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../widgets/haptic_touchable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../services/matcher_service.dart';
import '../../services/push_notification_service.dart';

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
  String _username = "Seeker";
  String _realName = "Seeker";
  bool _isAnonymous = true;
  final List<double> _moodScores = [];
  bool _dailyCheckInCompleted = false;

  // Centralized List of All Peer Listeners with their specialties & bio details
  List<Map<String, dynamic>> _allListeners = [];
  bool _isLoadingListeners = true;

  // List of listeners marked as regulars
  final List<String> _regularListenerNames = [];

  @override
  void initState() {
    super.initState();
    _loadUserDataAndListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService().initialize(context);
    });
  }

  Future<void> _loadUserDataAndListeners() async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      List<String> langs = ['en'];
      
      if (authUser != null) {
        final user = await UserService().getUser(authUser.uid);
        if (user != null) {
          if (mounted) {
            setState(() {
              _username = user.displayName.isNotEmpty ? user.displayName : (authUser.displayName ?? 'Seeker');
              _realName = authUser.displayName?.isNotEmpty == true
                  ? authUser.displayName!
                  : (authUser.email?.split('@').first ?? user.displayName);
              if (user.seekerData != null && user.seekerData!.safeCircle.isNotEmpty) {
                _regularListenerNames.clear();
                _regularListenerNames.addAll(user.seekerData!.safeCircle);
              }
            });
          }
          if (user.seekerData != null && user.seekerData!.preferredLanguages.isNotEmpty) {
            langs = user.seekerData!.preferredLanguages;
          }
        } else if (authUser.displayName != null && authUser.displayName!.isNotEmpty) {
          if (mounted) {
            setState(() {
              _username = authUser.displayName!;
              _realName = authUser.displayName!;
            });
          }
        }
      }
      
      final matcher = MatcherService();
      final listeners = await matcher.getOnlineListeners(langs);
      
      if (mounted) {
        setState(() {
          _allListeners = listeners.map((l) => {
            'uid': l.uid,
            'name': l.displayName.isEmpty ? 'Anonymous Listener' : l.displayName,
            'rating': l.listenerData?.stats?.rating.toStringAsFixed(1) ?? '5.0',
            'sessions': l.listenerData?.stats?.minutesListened ?? 0,
            'active': l.listenerData?.isOnline ?? false,
            'avatarColor': SafeTalkTheme.brandSage,
            'specialties': l.listenerData?.specialties.isNotEmpty == true ? l.listenerData!.specialties : ['Listening'],
            'bio': (l.listenerData?.bio.isNotEmpty ?? false) ? l.listenerData!.bio : 'A compassionate ear ready to listen without judgment.',
            'latestNote': 'No previous sessions',
          }).toList();
          _isLoadingListeners = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingListeners = false;
        });
      }
    }
  }

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
    
    targetScreen = SessionChatScreen(
      sessionId: SessionController().currentSessionId ?? '',
      myUid: SessionController().firebaseUid ?? '',
      partnerName: listenerName,
      isSeeker: true,
    );
    
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
                    sessionId: SessionController().currentSessionId ?? '',
                    myUid: SessionController().firebaseUid ?? '',
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
                    sessionId: SessionController().currentSessionId ?? '',
                    myUid: SessionController().firebaseUid ?? '',
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
