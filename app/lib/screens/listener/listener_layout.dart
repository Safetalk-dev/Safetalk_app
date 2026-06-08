import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import 'accept_user_screen.dart';
import 'dashboard_screen.dart';
import '../shared/history_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import '../../widgets/haptic_touchable.dart';
import '../../controllers/session_controller.dart';

class ListenerLayout extends StatefulWidget {
  final VoidCallback onLogout;

  const ListenerLayout({super.key, required this.onLogout});

  @override
  State<ListenerLayout> createState() => _ListenerLayoutState();
}

class _ListenerLayoutState extends State<ListenerLayout> {
  int _currentIndex = 0;
  bool _showingNotifications = false;
  bool _isOnline = true;
  bool _hasIncomingRequest = false;

  @override
  void initState() {
    super.initState();
    SessionController().addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    SessionController().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    final phase = SessionController().phase;
    setState(() {
      _hasIncomingRequest = phase == SessionPhase.seekerRequesting ||
          phase == SessionPhase.listenerIncoming;
    });
  }

  void _toggleOnlineStatus(bool value) {
    setState(() {
      _isOnline = value;
    });
  }

  Widget _buildBody() {
    if (_showingNotifications) {
      return ListenerNotificationScreen(onBack: () {
        setState(() => _showingNotifications = false);
      });
    }

    switch (_currentIndex) {
      case 0:
        return ListenerDashboardScreen(
          isOnline: _isOnline,
          onOnlineChanged: _toggleOnlineStatus,
          onOpenRequests: () {
            setState(() {
              _currentIndex = 1;
            });
          },
        );
      case 1:
        return AcceptUserScreen(
          isOnline: _isOnline,
          onAcceptConnection: () {
            // Seeker is paying, call will launch automatically when payment completes
          },
        );
      case 2:
        return const HistoryScreen(isSeeker: false);
      case 3:
        return ListenerProfileScreen(
          isOnline: _isOnline,
          onOnlineChanged: _toggleOnlineStatus,
          onLogout: widget.onLogout,
        );
      default:
        return ListenerDashboardScreen(
          isOnline: _isOnline,
          onOnlineChanged: _toggleOnlineStatus,
          onOpenRequests: () {},
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: SafeTalkTheme.bgMidnight,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                // Route to profile screen to toggle online status
                setState(() {
                  _currentIndex = 3;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isOnline
                      ? SafeTalkTheme.getListenerColor(SessionController().isTherapist).withValues(alpha: 0.12)
                      : SafeTalkTheme.textMuted.withValues(alpha: 0.12),
                  borderRadius: SafeTalkTheme.pillRadius,
                  border: Border.all(
                    color: _isOnline
                        ? SafeTalkTheme.getListenerColor(SessionController().isTherapist).withValues(alpha: 0.3)
                        : SafeTalkTheme.borderSage,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lens,
                      color: _isOnline ? SafeTalkTheme.getListenerColor(SessionController().isTherapist) : SafeTalkTheme.textMuted,
                      size: 8,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOnline ? 'Online & Available' : 'Offline',
                      style: SafeTalkTheme.captionStyle(
                        color: _isOnline ? SafeTalkTheme.getListenerColorLight(SessionController().isTherapist) : SafeTalkTheme.textSecondary,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Notifications Icon
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  _showingNotifications ? Icons.notifications : Icons.notifications_none,
                  color: _showingNotifications ? SafeTalkTheme.getListenerColor(SessionController().isTherapist) : SafeTalkTheme.textPrimary,
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: SafeTalkTheme.getListenerColor(SessionController().isTherapist),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              setState(() {
                _showingNotifications = !_showingNotifications;
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
      
      // Floating Custom Glassmorphic Navigation Bar
      bottomNavigationBar: _showingNotifications
          ? null
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
                      _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
                      _buildNavItem(1, Icons.assignment_outlined, Icons.assignment_rounded, 'Requests', showBadge: _hasIncomingRequest),
                      _buildNavItem(2, Icons.history_rounded, Icons.history_rounded, 'History'),
                      _buildNavItem(3, Icons.account_circle_outlined, Icons.account_circle_rounded, 'Profile'),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label, {bool showBadge = false}) {
    final isSelected = _currentIndex == index;
    final activeColor = SafeTalkTheme.getListenerColor(SessionController().isTherapist);

    return HapticTouchable(
      onTap: () => setState(() {
        _currentIndex = index;
        _showingNotifications = false;
      }),
      pressedScale: 0.95,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
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
              if (showBadge)
                Positioned(
                  top: 2,
                  right: 10,
                  child: Container(
                    height: 9,
                    width: 9,
                    decoration: BoxDecoration(
                      color: SafeTalkTheme.brandTerracotta,
                      shape: BoxShape.circle,
                      border: Border.all(color: SafeTalkTheme.bgMidnight, width: 1.5),
                    ),
                  ),
                ),
            ],
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
