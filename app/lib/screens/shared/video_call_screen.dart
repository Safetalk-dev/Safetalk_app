import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../widgets/haptic_touchable.dart';
import '../../widgets/pin_sheet.dart';

class VideoCallScreen extends StatefulWidget {
  final String partnerName;
  final bool isSeekerCaller;
  final VoidCallback? onSessionEnd;

  const VideoCallScreen({
    super.key,
    required this.partnerName,
    required this.isSeekerCaller,
    this.onSessionEnd,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMuted = false;
  bool _isCamOff = false;
  int _sessionTimeRemaining = 420; // 7 minutes session countdown standard
  Timer? _callTimer;
  bool _showingNotesDrawer = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // For Counselor/Listener or Seeker/User notes safety
    if (widget.isSeekerCaller) {
      ChatController().ensureUserThread(widget.partnerName);
      final activeThread = ChatController().userThreads.firstWhere(
        (t) => t['name'] == widget.partnerName,
        orElse: () => ChatController().userThreads[0],
      );
      _notesController.text = activeThread['notes'] ?? '';
    } else {
      final threadExists = ChatController().listenerThreads.any((t) => t['name'] == widget.partnerName);
      if (!threadExists) {
        ChatController().listenerThreads.add({
          'name': widget.partnerName,
          'status': 'Video Call Session',
          'avatarColor': SafeTalkTheme.brandTerracotta,
          'online': false,
          'unread': false,
          'lastMessage': 'Video Call connected',
          'time': 'Now',
          'notes': '',
          'messages': []
        });
      }
      
      // Load current notes initially
      final activeThread = ChatController().listenerThreads.firstWhere((t) => t['name'] == widget.partnerName);
      _notesController.text = activeThread['notes'] ?? '';
    }

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_sessionTimeRemaining > 0) {
        setState(() {
          _sessionTimeRemaining--;
        });
      } else {
        timer.cancel();
        _concludeSession();
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _promptEndSession() {
    final activeThemeColor = widget.isSeekerCaller
        ? SafeTalkTheme.brandTerracotta
        : SafeTalkTheme.getListenerColor(SessionController().isTherapist);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SafeTalkTheme.bgMidnight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: activeThemeColor.withValues(alpha: 0.3)),
        ),
        title: Text(
          'End Call?',
          style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to end this secure support video call? Exiting concludes this matching session.',
          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _concludeSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SafeTalkTheme.brandTerracotta,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'End Call',
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
            ),
          ),
        ],
      ),
    );
  }

  void _concludeSession() {
    _callTimer?.cancel();
    widget.onSessionEnd?.call();
    if (widget.isSeekerCaller) {
      _showRatingSheet();
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your 7-minute support session has safely concluded. Take a deep breath.',
            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
          ),
          backgroundColor: SafeTalkTheme.getListenerColor(SessionController().isTherapist),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showRatingSheet() {
    int companionRating = 5;
    int sessionRating = 5;
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.3), width: 2),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.12),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: SafeTalkTheme.brandTerracotta,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Share Your Experience',
                        style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Your feedback is anonymized and keeps space safe.',
                        textAlign: TextAlign.center,
                        style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: SafeTalkTheme.borderSage, height: 1),
                    const SizedBox(height: 20),

                    Text(
                      'RATE YOUR COMPANION (${widget.partnerName})',
                      style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary)
                          .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starScore = index + 1;
                        final isSelected = starScore <= companionRating;
                        return HapticTouchable(
                          onTap: () {
                            setDialogState(() {
                              companionRating = starScore;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Icon(
                              isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                              color: SafeTalkTheme.brandGold,
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'RATE THERAPEUTIC SESSION BALANCE',
                      style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary)
                          .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starScore = index + 1;
                        final isSelected = starScore <= sessionRating;
                        return HapticTouchable(
                          onTap: () {
                            setDialogState(() {
                              sessionRating = starScore;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Icon(
                              isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                              color: SafeTalkTheme.brandTerracotta,
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'ADD OPTIONAL REFLECTIONS',
                      style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary)
                          .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: SafeTalkTheme.bgMidnight,
                        borderRadius: SafeTalkTheme.standardRadius,
                        border: Border.all(color: SafeTalkTheme.borderSage),
                      ),
                      child: TextField(
                        controller: feedbackController,
                        maxLines: 2,
                        style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'How did this session affect your mood?...',
                          hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textMuted),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              feedbackController.dispose();
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SafeTalkTheme.brandTerracotta,
                              side: const BorderSide(color: SafeTalkTheme.borderSage, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Skip',
                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandTerracotta, bold: true),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              feedbackController.dispose();
                              Navigator.pop(context);
                              Navigator.pop(context);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Thank you. Your feedback has been saved securely to balance future matching filters!',
                                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                                  ),
                                  backgroundColor: SafeTalkTheme.brandSage,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SafeTalkTheme.brandTerracotta,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            child: Text(
                              'Submit',
                              style: SafeTalkTheme.bodyStyle(color: Colors.white, bold: true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showingNotesDrawer) {
          _closeNotesDrawer();
        } else {
          _promptEndSession();
        }
      },
      child: Scaffold(
      body: Stack(
        children: [
          // 1. Fullscreen Main Camera Feed (Mocking the Peer's incoming video)
          _buildMainVideoFeed(),

          // Ambient top gradient overlay for text readability
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. Picture-in-Picture Local Camera Feed (PiP in Top-Right)
          Positioned(
            right: 20,
            top: 60,
            child: ClipRRect(
              borderRadius: SafeTalkTheme.organicCardRadius,
              child: Container(
                height: 140,
                width: 100,
                color: SafeTalkTheme.cardBg,
                child: Stack(
                  children: [
                    _buildLocalPiPFeed(),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'You',
                          style: SafeTalkTheme.captionStyle(color: Colors.white).copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Top Call Details Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.partnerName,
                            style: SafeTalkTheme.headingStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                height: 6,
                                width: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDuration(_sessionTimeRemaining),
                                style: SafeTalkTheme.captionStyle(color: Colors.white.withValues(alpha: 0.85)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: SafeTalkTheme.pillRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, color: Colors.green, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          'Encrypted Video Link',
                          style: SafeTalkTheme.captionStyle(color: Colors.white).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Floating Controls
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65), // Dark transparent overlay
                borderRadius: SafeTalkTheme.pillRadius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Camera On/Off
                  _buildFloatingControlItem(
                    icon: _isCamOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                    active: _isCamOff,
                    onTap: () => setState(() => _isCamOff = !_isCamOff),
                  ),

                  // Mute Mic
                  _buildFloatingControlItem(
                    icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    active: _isMuted,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),

                  // Flip Camera
                  _buildFloatingControlItem(
                    icon: Icons.flip_camera_ios_rounded,
                    active: false,
                    onTap: () {},
                  ),

                  // Secure Notes/Journal Toggle Button (visible to all roles)
                  _buildFloatingControlItem(
                    icon: widget.isSeekerCaller ? Icons.history_edu_outlined : Icons.note_alt_outlined,
                    active: _showingNotesDrawer,
                    onTap: _openNotesDrawer,
                  ),

                  // End Call Button
                  GestureDetector(
                    onTap: _promptEndSession,
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: SafeTalkTheme.brandTerracotta,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33C85B3F),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.call_end_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Notes drawer overlays (visible when drawer toggled open)
          if (_showingNotesDrawer) ...[
            Builder(
              builder: (context) {
                final activeThread = widget.isSeekerCaller
                    ? ChatController().userThreads.firstWhere(
                        (t) => t['name'] == widget.partnerName,
                        orElse: () => {
                          'name': widget.partnerName,
                          'status': 'Video Call Session',
                          'avatarColor': SafeTalkTheme.brandTerracotta,
                          'online': false,
                          'unread': false,
                          'lastMessage': 'Video Call connected',
                          'time': 'Now',
                          'notes': '',
                          'messages': []
                        },
                      )
                    : ChatController().listenerThreads.firstWhere(
                        (t) => t['name'] == widget.partnerName,
                        orElse: () => {
                          'name': widget.partnerName,
                          'status': 'Video Call Session',
                          'avatarColor': SafeTalkTheme.brandTerracotta,
                          'online': false,
                          'unread': false,
                          'lastMessage': 'Video Call connected',
                          'time': 'Now',
                          'notes': '',
                          'messages': []
                        },
                      );
                return _buildNotesDrawer(activeThread);
              }
            ),
          ],
        ],
      ),
    ),
    );
  }

  // MOCK MAIN PEER VIEWPORT BACKGROUND
  Widget _buildMainVideoFeed() {
    if (widget.isSeekerCaller) {
      // Seeker is looking at the Listener: Render a comforting light therapy room
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8ECE9), Color(0xFFD3DCD7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mock warm therapy scene with simple vectors
              Icon(Icons.spa, color: SafeTalkTheme.brandSage.withValues(alpha: 0.3), size: 100),
              const SizedBox(height: 16),
              Text(
                'Quiet Sanctuary Session',
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandSage.withValues(alpha: 0.8), bold: true),
              ),
            ],
          ),
        ),
      );
    } else {
      // Listener is looking at the Seeker: Seeker is Anonymous by default
      return Container(
        color: SafeTalkTheme.bgMidnight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.12),
                  border: Border.all(color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.psychology, color: SafeTalkTheme.brandTerracotta, size: 54),
              ),
              const SizedBox(height: 24),
              Text(
                'Seeker Anonymity Shield Active',
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary, bold: true),
              ),
              const SizedBox(height: 6),
              Text(
                'Their camera is securely hidden to protect identity.',
                style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }
  }

  // MOCK LOCAL PIP VIEWPORT
  Widget _buildLocalPiPFeed() {
    if (_isCamOff) {
      return Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white38, size: 24),
        ),
      );
    }

    if (widget.isSeekerCaller) {
      // Seeker is local: Displays their anonymous silhouette to emphasize privacy
      return Container(
        color: SafeTalkTheme.bgMidnight,
        child: Center(
          child: Icon(
            Icons.account_circle,
            color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.3),
            size: 48,
          ),
        ),
      );
    } else {
      // Listener is local: Displays their warm workspace
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFF3F1), Color(0xFFDDE6E2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.face_retouching_natural_rounded,
            color: SafeTalkTheme.brandSage.withValues(alpha: 0.3),
            size: 40,
          ),
        ),
      );
    }
  }

  Widget _buildFloatingControlItem({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? SafeTalkTheme.brandTerracotta : Colors.white.withValues(alpha: 0.12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // --- CONFIDENTIAL NOTES DRAWER HELPERS ---
  void _openNotesDrawer() {
    if (ChatController().isVaultEnabled) {
      ChatController().lockVault();
    }
    setState(() {
      _showingNotesDrawer = true;
    });
  }

  void _closeNotesDrawer() {
    if (ChatController().isVaultEnabled) {
      ChatController().lockVault();
    }
    setState(() {
      _showingNotesDrawer = false;
    });
  }

  void _saveNotes() {
    if (widget.isSeekerCaller) {
      ChatController().saveUserNotes(widget.partnerName, _notesController.text);
    } else {
      ChatController().saveListenerNotes(widget.partnerName, _notesController.text);
      if (ChatController().isVaultEnabled) {
        ChatController().lockVault();
      }
    }
    setState(() {
      _showingNotesDrawer = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isSeekerCaller ? 'Journal securely saved.' : 'Notes securely saved & encrypted.',
          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight),
        ),
        backgroundColor: widget.isSeekerCaller
            ? SafeTalkTheme.brandTerracotta
            : SafeTalkTheme.getListenerColor(SessionController().isTherapist),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildNotesDrawer(Map<String, dynamic> activeThread) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isTherapist = SessionController().isTherapist;
    final brandColor = widget.isSeekerCaller
        ? SafeTalkTheme.brandTerracotta
        : SafeTalkTheme.getListenerColor(isTherapist);
    
    final double drawerHeight = isKeyboardOpen 
        ? (screenHeight - MediaQuery.of(context).viewInsets.bottom - 40)
        : (screenHeight * 0.8);

    final double textFieldHeight = isKeyboardOpen
        ? screenHeight * 0.18
        : screenHeight * 0.40;

    final bool isLocked = !widget.isSeekerCaller && ChatController().isVaultEnabled && ChatController().userPin == null;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          height: drawerHeight,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: isKeyboardOpen ? 24 : 40,
          ),
          decoration: BoxDecoration(
            color: SafeTalkTheme.cardBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.isSeekerCaller ? 'Secure Session Journal' : 'Encrypted Journal Notes',
                      style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: SafeTalkTheme.textSecondary),
                    onPressed: _closeNotesDrawer,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.isSeekerCaller
                    ? 'Your private, encrypted reflections and journals for this session.'
                    : 'Confidential records related to ${activeThread['name']}. These notes are stored locally and encrypted.',
                style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLocked) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: brandColor.withValues(alpha: 0.12),
                                ),
                                child: Icon(
                                  Icons.lock_person_rounded,
                                  color: brandColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Encrypted Journal is Locked',
                                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true)
                                    .copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'To protect seeker confidentiality, this journal is sealed with a PIN-derived encryption key. Decryption keys are held in volatile memory only.',
                                  textAlign: TextAlign.center,
                                  style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: HapticTouchable(
                                  onTap: () {
                                    PinSheet.show(
                                      context: context,
                                      mode: PinSheetMode.unlock,
                                      onSuccess: (pin) {
                                        setState(() {
                                          _notesController.text = activeThread['notes'] ?? '';
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Journal notes unlocked successfully.',
                                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                                            ),
                                            backgroundColor: brandColor,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: brandColor,
                                      borderRadius: SafeTalkTheme.organicCardRadius,
                                    ),
                                    child: Text(
                                      'Unlock Journal Notes',
                                      style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          height: textFieldHeight,
                          child: TextField(
                            controller: _notesController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                             decoration: InputDecoration(
                              hintText: widget.isSeekerCaller
                                  ? 'Write down your thoughts, breakthroughs, and reflections...'
                                  : 'Add counseling notes or reminders...',
                              hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textMuted),
                              filled: true,
                              fillColor: SafeTalkTheme.bgMidnight,
                              contentPadding: const EdgeInsets.all(16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: SafeTalkTheme.standardRadius,
                                borderSide: const BorderSide(color: SafeTalkTheme.borderSage, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: SafeTalkTheme.standardRadius,
                                borderSide: BorderSide(color: brandColor, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!isLocked) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveNotes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      foregroundColor: SafeTalkTheme.bgMidnight,
                      shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.organicCardRadius),
                    ),
                    child: Text(
                      widget.isSeekerCaller ? 'Save Private Journal' : 'Save Encrypted Journal',
                      style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                    ),
                  ),
                ),
              ],
            ],
          ),

        ),
      ),
    );
  }
}

