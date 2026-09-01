import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/haptic_touchable.dart';
import '../../controllers/session_controller.dart';
import '../../widgets/safety_report_dialog.dart';
import '../../widgets/pin_sheet.dart';
import '../../controllers/chat_controller.dart';
import '../../services/listener_settings_service.dart';

import '../../services/session_service.dart';
import '../../services/vault_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'voice_call_screen.dart';

class SessionChatScreen extends StatefulWidget {
  final String sessionId;
  final String myUid;
  final String partnerName;
  final bool isSeeker; // true if seeker, false if listener/therapist
  final VoidCallback? onSessionEnd;

  const SessionChatScreen({
    super.key,
    required this.sessionId,
    required this.myUid,
    required this.partnerName,
    required this.isSeeker,
    this.onSessionEnd,
  });

  @override
  State<SessionChatScreen> createState() => _SessionChatScreenState();
}

class _SessionChatScreenState extends State<SessionChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _sessionTimeRemaining = 600; // 10 minutes session countdown standard
  Timer? _sessionTimer;
  
  final SessionService _sessionService = SessionService();
  final VaultService _vaultService = VaultService();

  // Counselor Notes & Dialog Controls
  final TextEditingController _notesController = TextEditingController();
  bool _showingNotesDrawer = false;

  @override
  void initState() {
    super.initState();
    ChatController().addListener(_onChatControllerChanged);

    if (widget.isSeeker) {
      ChatController().ensureUserThread(widget.partnerName);
      final activeThread = ChatController().userThreads.firstWhere(
        (t) => t['name'] == widget.partnerName,
        orElse: () => ChatController().userThreads[0],
      );
      _notesController.text = activeThread['notes'] ?? '';
    } else if (ChatController().listenerThreads.isNotEmpty) {
      final activeThread = ChatController().listenerThreads.firstWhere(
        (t) => t['name'] == widget.partnerName,
        orElse: () => ChatController().listenerThreads[0],
      );
      _notesController.text = activeThread['notes'] ?? '';
    }

    // Active session timer
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
    ChatController().removeListener(_onChatControllerChanged);
    _sessionTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onChatControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      final encryptedText = await _vaultService.encryptString(widget.sessionId, messageText);
      await _sessionService.sendMessage(widget.sessionId, encryptedText, widget.myUid);
      _scrollToBottom();
    } catch (e) {
      debugPrint('Encryption error: $e');
    }
  }

  void _concludeSession() {
    _sessionTimer?.cancel();
    widget.onSessionEnd?.call();
    if (widget.isSeeker) {
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
                              backgroundColor: SafeTalkTheme.brandSage,
                              foregroundColor: SafeTalkTheme.bgMidnight,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            child: Text(
                              'Submit',
                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
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
          'End Session?',
          style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to end this secure support session? Exiting concludes all matching loops.',
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
              'End Session',
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimer(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isTherapist = SessionController().isTherapist;
    final brandColor = SafeTalkTheme.getListenerColor(isTherapist);
    final brandColorLight = SafeTalkTheme.getListenerColorLight(isTherapist);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _promptEndSession();
      },
      child: Scaffold(
        backgroundColor: SafeTalkTheme.bgMidnight,
      body: Stack(
        children: [
          // Elegant premium gradient backgrounds
          Positioned(
            top: -120,
            right: -100,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: brandColor.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: CircleAvatar(
              radius: 250,
              backgroundColor: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.05),
            ),
          ),

          // Main layout Column
          Column(
            children: [
              // Confidential Encrypted Header
              SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.all(16),
                  decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: brandColor.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      // Seeker detail or generic Session Chat status
                      if (!widget.isSeeker) ...[
                        // Seeker avatar
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.2),
                              child: const Icon(Icons.psychology, color: SafeTalkTheme.brandTerracotta, size: 18),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                height: 10,
                                width: 10,
                                decoration: BoxDecoration(
                                  color: SafeTalkTheme.brandSage,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: SafeTalkTheme.cardBg, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.partnerName,
                                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 14.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Active Match • 97%',
                                style: SafeTalkTheme.captionStyle(color: brandColorLight).copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Action Buttons for Listener
                        Container(
                          decoration: BoxDecoration(
                            color: brandColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.note_alt_outlined, color: brandColorLight, size: 18),
                            tooltip: 'Secure Session Notes',
                            onPressed: () {
                              if (ChatController().isVaultEnabled) {
                                ChatController().lockVault();
                              }
                              setState(() {
                                _showingNotesDrawer = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: SafeTalkTheme.brandGold.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.support_agent_rounded, color: SafeTalkTheme.brandGold, size: 18),
                            tooltip: 'Recommend Seeker to Clinical Supervisor',
                            onPressed: () => _showSupervisionDialog(context, widget.partnerName),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Theme(
                          data: Theme.of(context).copyWith(
                            cardColor: SafeTalkTheme.cardBg,
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: SafeTalkTheme.textSecondary),
                            shape: RoundedRectangleBorder(
                              borderRadius: SafeTalkTheme.standardRadius,
                              side: const BorderSide(color: SafeTalkTheme.borderSage, width: 1),
                            ),
                            elevation: 4,
                            onSelected: (value) {
                              if (value == 'supervision') {
                                _showSupervisionDialog(context, widget.partnerName);
                              } else if (value == 'report') {
                                _showReportSeekerDialog(context, widget.partnerName);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'supervision',
                                child: Row(
                                  children: [
                                    Icon(Icons.support_agent_rounded, color: brandColorLight, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Supervisor Oversight',
                                      style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(height: 1),
                              PopupMenuItem(
                                value: 'report',
                                child: Row(
                                  children: [
                                    const Icon(Icons.flag_outlined, color: SafeTalkTheme.brandGold, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Report Seeker',
                                      style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandGold, bold: true),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                      ] else ...[
                        // Status and Timer Indicators for Seeker
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SESSION CHAT',
                                  style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary)
                                      .copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  color: brandColorLight,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Double-Encrypted',
                                  style: SafeTalkTheme.captionStyle(color: brandColorLight),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: brandColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.history_edu_outlined, color: brandColorLight, size: 18),
                            tooltip: 'Secure Session Journal',
                            onPressed: () {
                              setState(() {
                                _showingNotesDrawer = true;
                              });
                            },
                          ),
                        ),
                        const Spacer(),
                      ],

                      // Active Timer Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: SafeTalkTheme.bgMidnight.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: brandColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: SafeTalkTheme.brandTerracotta,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimer(_sessionTimeRemaining),
                              style: SafeTalkTheme.bodyStyle(
                                color: SafeTalkTheme.textPrimary,
                                bold: true,
                              ).copyWith(fontFamily: 'monospace', fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Call Button
                      HapticTouchable(
                        onTap: () async {
                          try {
                            final callable = FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
                            final result = await callable.call({'channelName': widget.sessionId});
                            final data = result.data as Map<String, dynamic>;
                            
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VoiceCallScreen(
                                  channelName: data['channelName'],
                                  token: data['token'],
                                  appId: data['appId'],
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to connect call: $e')));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SafeTalkTheme.brandGold.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: SafeTalkTheme.brandGold.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(
                            Icons.phone_rounded,
                            color: SafeTalkTheme.brandGold,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Exit Button
                      HapticTouchable(
                        onTap: _promptEndSession,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: SafeTalkTheme.brandTerracotta,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Chat Messages Area
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _sessionService.streamMessages(widget.sessionId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading messages'));
                    }
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final _messages = snapshot.data!;
                    
                    // Schedule scroll to bottom when new messages arrive
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg['senderId'] == widget.myUid;

                        // Asymmetric borders
                        final radius = isMe
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(4),
                                topRight: Radius.circular(20),
                              )
                            : const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                                bottomLeft: Radius.circular(4),
                              );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: brandColor.withValues(alpha: 0.2),
                                  child: Text(
                                    widget.partnerName.isNotEmpty ? widget.partnerName[0] : 'U',
                                    style: SafeTalkTheme.captionStyle(color: brandColor).copyWith(fontSize: 9),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isMe ? brandColor : SafeTalkTheme.cardBg,
                                    borderRadius: radius,
                                    border: isMe
                                        ? null
                                        : Border.all(color: SafeTalkTheme.borderSage, width: 1.2),
                                  ),
                                  child: FutureBuilder<String>(
                                    future: _vaultService.decryptString(widget.sessionId, msg['text'] ?? ''),
                                    builder: (context, decSnapshot) {
                                      final decText = decSnapshot.hasData ? decSnapshot.data! : (decSnapshot.hasError ? 'Decrypt Error' : '...');
                                      return Text(
                                        decText,
                                        style: SafeTalkTheme.bodyStyle(
                                          color: isMe ? SafeTalkTheme.bgMidnight : SafeTalkTheme.textPrimary,
                                        ).copyWith(fontSize: 14.5),
                                      );
                                    }
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                ),
              ),

              // Calming prompt chips for user
              if (widget.isSeeker)
                Container(
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCalmChip("Thank you for listening."),
                      _buildCalmChip("I need a moment to think."),
                      _buildCalmChip("Can we try a breathing exercise?"),
                    ],
                  ),
                ),

              // Canned empathy response macros panel for Listener
              if (!widget.isSeeker)
                Container(
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildMacroChip("I hear you. That sounds incredibly heavy."),
                      _buildMacroChip("Take all the time you need. I'm holding this space."),
                      _buildMacroChip("What does your body feel like right now?"),
                      _buildMacroChip("Your feelings are completely valid."),
                    ],
                  ),
                ),

              // Bottom Input Bar
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: SafeTalkTheme.bgMidnight,
                    border: Border(top: BorderSide(color: SafeTalkTheme.borderSage, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: SafeTalkTheme.cardBg,
                            borderRadius: SafeTalkTheme.pillRadius,
                            border: Border.all(color: SafeTalkTheme.borderSage, width: 1),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: widget.isSeeker ? "Share what's on your mind..." : "Answer with gentle empathy...",
                              hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textMuted),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.send_rounded, color: brandColor),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Secure Notes/Journal drawer overlay
          if (_showingNotesDrawer)
            _buildNotesDrawer(
              widget.isSeeker
                  ? ChatController().userThreads.firstWhere(
                      (t) => t['name'] == widget.partnerName,
                      orElse: () => {
                        'name': widget.partnerName,
                        'status': 'Active Match',
                        'avatarColor': SafeTalkTheme.brandTerracotta,
                        'online': true,
                        'unread': false,
                        'lastMessage': '',
                        'time': 'Now',
                        'notes': '',
                        'messages': []
                      },
                    )
                  : ChatController().listenerThreads.firstWhere(
                      (t) => t['name'] == widget.partnerName,
                      orElse: () => {
                        'name': widget.partnerName,
                        'status': 'Active Match • 97%',
                        'avatarColor': SafeTalkTheme.brandTerracotta,
                        'online': true,
                        'unread': false,
                        'lastMessage': '',
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

  Widget _buildCalmChip(String text) {
    final isTherapist = SessionController().isTherapist;
    final brandColor = SafeTalkTheme.getListenerColor(isTherapist);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(
          text,
          style: SafeTalkTheme.captionStyle(color: brandColor),
        ),
        backgroundColor: SafeTalkTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: SafeTalkTheme.pillRadius,
          side: const BorderSide(color: SafeTalkTheme.borderSage, width: 1),
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        onPressed: () {
          setState(() {
            _messageController.text = text;
          });
        },
      ),
    );
  }

  void _saveNotes() {
    if (widget.isSeeker) {
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
          widget.isSeeker ? 'Journal securely saved & encrypted.' : 'Notes securely saved & encrypted.',
          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight),
        ),
        backgroundColor: widget.isSeeker
            ? SafeTalkTheme.brandTerracotta
            : SafeTalkTheme.getListenerColor(SessionController().isTherapist),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReportSeekerDialog(BuildContext context, String seekerName) {
    SafetyReportDialog.show(
      context: context,
      targetName: seekerName,
      isReportingListener: false,
      onSubmit: (reason, details) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report submitted securely. Thank you for keeping space safe.',
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
            ),
            backgroundColor: SafeTalkTheme.brandGold,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showSupervisionDialog(BuildContext context, String seekerName) {
    final isTherapist = SessionController().isTherapist;
    final brandColorLight = SafeTalkTheme.getListenerColorLight(isTherapist);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SafeTalkTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.standardRadius),
        title: Row(
          children: [
            Icon(Icons.support_agent_rounded, color: brandColorLight),
            const SizedBox(width: 10),
            Text(
              'Supervisor Oversight',
              style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Would you like to recommend $seekerName to a Clinical Supervisor? This triggers active clinical supervisor oversight standby for the remainder of this session.',
          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ListenerSettingsService().setSupervisionEnabled(true);
              
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: SafeTalkTheme.bgMidnight, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Oversight Activated',
                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true).copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Escalated to Clinical Supervisor Amber R. Supervision standby active.',
                              style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.bgMidnight.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: SafeTalkTheme.brandGold,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.standardRadius),
                ),
              );
            },
            child: Text(
              'Recommend & Escalate',
              style: SafeTalkTheme.bodyStyle(color: brandColorLight, bold: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String text) {
    final isTherapist = SessionController().isTherapist;
    final brandColorLight = SafeTalkTheme.getListenerColorLight(isTherapist);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(
          text,
          style: SafeTalkTheme.captionStyle(color: brandColorLight),
        ),
        backgroundColor: SafeTalkTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: SafeTalkTheme.pillRadius,
          side: const BorderSide(color: SafeTalkTheme.borderSage, width: 1),
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        onPressed: () {
          setState(() {
            _messageController.text = text;
          });
        },
      ),
    );
  }

  Widget _buildNotesDrawer(Map<String, dynamic> activeThread) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isTherapist = SessionController().isTherapist;
    final brandColor = widget.isSeeker
        ? SafeTalkTheme.brandTerracotta
        : SafeTalkTheme.getListenerColor(isTherapist);
    
    final double drawerHeight = isKeyboardOpen 
        ? (screenHeight - MediaQuery.of(context).viewInsets.bottom - 40)
        : (screenHeight * 0.8);

    final double textFieldHeight = isKeyboardOpen
        ? screenHeight * 0.18
        : screenHeight * 0.40;

    final bool isLocked = !widget.isSeeker && ChatController().isVaultEnabled && ChatController().userPin == null;

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
                      widget.isSeeker ? 'Secure Session Journal' : 'Encrypted Journal Notes',
                      style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: SafeTalkTheme.textSecondary),
                    onPressed: () {
                      if (ChatController().isVaultEnabled) {
                        ChatController().lockVault();
                      }
                      setState(() {
                        _showingNotesDrawer = false;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.isSeeker
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
                              hintText: widget.isSeeker
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
                      widget.isSeeker ? 'Save Private Journal' : 'Save Encrypted Journal',
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
