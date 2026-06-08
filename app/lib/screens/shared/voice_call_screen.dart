import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../widgets/pin_sheet.dart';
import '../../widgets/haptic_touchable.dart';
import '../../widgets/breathing_pulse.dart';
import 'dart:async';

class VoiceCallScreen extends StatefulWidget {
  final String partnerName;
  final bool isSeekerCaller; // true if seeker calling, false if listener calling
  final VoidCallback? onSessionEnd; // Optional hook for caller to handle post-call cleanup

  const VoiceCallScreen({
    super.key,
    required this.partnerName,
    required this.isSeekerCaller,
    this.onSessionEnd,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  int _sessionTimeRemaining = 600; // 10 minutes session countdown standard
  Timer? _sessionTimer;
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
          'status': 'Voice Call Session',
          'avatarColor': SafeTalkTheme.brandTerracotta,
          'online': false,
          'unread': false,
          'lastMessage': 'Voice Call connected',
          'time': 'Now',
          'notes': '',
          'messages': []
        });
      }
      
      // Load current notes initially
      final activeThread = ChatController().listenerThreads.firstWhere((t) => t['name'] == widget.partnerName);
      _notesController.text = activeThread['notes'] ?? '';
    }
    // Paid session countdown timer
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    _sessionTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _promptEndSession() {
    final isTherapist = SessionController().isTherapist;
    final brandColor = SafeTalkTheme.getListenerColor(isTherapist);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SafeTalkTheme.bgMidnight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: brandColor.withValues(alpha: 0.3)),
        ),
        title: Text(
          'End Call?',
          style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to end this secure support voice call? Exiting concludes this matching session.',
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
    _sessionTimer?.cancel();
    widget.onSessionEnd?.call();
    if (widget.isSeekerCaller) {
      _showRatingSheet();
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your 10-minute support session has safely concluded. Take a deep breath.',
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
    final activeThemeColor = widget.isSeekerCaller
        ? SafeTalkTheme.brandTerracotta
        : SafeTalkTheme.getListenerColor(SessionController().isTherapist);



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
        backgroundColor: SafeTalkTheme.bgMidnight,
        body: Stack(
          children: [
            Container(
              decoration: SafeTalkTheme.ambientBackground,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    children: [
                      // Top encrypted header badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: SafeTalkTheme.brandSage.withValues(alpha: 0.1),
                          borderRadius: SafeTalkTheme.pillRadius,
                          border: Border.all(color: SafeTalkTheme.borderSage, width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.security, color: SafeTalkTheme.brandSage, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              'SECURE PAID SESSION ACTIVE',
                              style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandSage)
                                  .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(flex: 2),

                      // Soothing Pulsing Call Wave Avatar
                      BreathingPulse(
                        size: 150,
                        showText: false,
                        subtitle: _formatDuration(_sessionTimeRemaining),
                      ),
                      
                      const SizedBox(height: 36),

                      // Call Partner Details
                      Text(
                        widget.partnerName,
                        style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(
                          fontSize: 28,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isSeekerCaller
                            ? 'Confidential Seeker Connection'
                            : 'Empathetic Companion Support Line',
                        style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
                      ),

                      const Spacer(flex: 3),

                      // Call Controls floating bar
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                          borderRadius: SafeTalkTheme.pillRadius,
                          border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Mute Icon Button
                            _buildControlItem(
                              icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                              label: 'Mute',
                              active: _isMuted,
                              color: activeThemeColor,
                              onTap: () {
                                setState(() {
                                  _isMuted = !_isMuted;
                                });
                              },
                            ),
                            
                            // End Call Button
                            HapticTouchable(
                              onTap: _promptEndSession,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 58,
                                    width: 58,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: SafeTalkTheme.brandTerracotta,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x33C85B3F),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.call_end_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'End',
                                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Speaker Icon Button
                            _buildControlItem(
                              icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                              label: 'Speaker',
                              active: _isSpeakerOn,
                              color: activeThemeColor,
                              onTap: () {
                                setState(() {
                                  _isSpeakerOn = !_isSpeakerOn;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),

            // 1. Floating top-right notes/journal toggle button (visible to all roles)
            Positioned(
              top: 20,
              right: 20,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: activeThemeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeThemeColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      widget.isSeekerCaller ? Icons.history_edu_outlined : Icons.note_alt_outlined,
                      color: activeThemeColor,
                      size: 22,
                    ),
                    tooltip: widget.isSeekerCaller ? 'Secure Session Journal' : 'Secure Session Notes',
                    onPressed: _openNotesDrawer,
                  ),
                ),
              ),
            ),

            // 2. Notes drawer overlays (visible when drawer toggled open)
            if (_showingNotesDrawer)
              _buildNotesDrawer(
                widget.isSeekerCaller
                    ? ChatController().userThreads.firstWhere(
                        (t) => t['name'] == widget.partnerName,
                        orElse: () => {
                          'name': widget.partnerName,
                          'status': 'Voice Call Session',
                          'avatarColor': SafeTalkTheme.brandTerracotta,
                          'online': false,
                          'unread': false,
                          'lastMessage': 'Voice Call connected',
                          'time': 'Now',
                          'notes': '',
                          'messages': []
                        },
                      )
                    : ChatController().listenerThreads.firstWhere(
                        (t) => t['name'] == widget.partnerName,
                        orElse: () => {
                          'name': widget.partnerName,
                          'status': 'Voice Call Session',
                          'avatarColor': SafeTalkTheme.brandTerracotta,
                          'online': false,
                          'unread': false,
                          'lastMessage': 'Voice Call connected',
                          'time': 'Now',
                          'notes': '',
                          'messages': []
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlItem({
    required IconData icon,
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? color : SafeTalkTheme.bgMidnight,
              border: Border.all(
                color: active ? Colors.transparent : SafeTalkTheme.borderSage,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: active ? SafeTalkTheme.bgMidnight : SafeTalkTheme.textPrimary,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
          ),
        ],
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

