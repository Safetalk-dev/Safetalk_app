import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../controllers/session_controller.dart';
import '../shared/session_chat_screen.dart';
import '../../widgets/breathing_pulse.dart';

import '../../models/session_model.dart';

class AcceptUserScreen extends StatefulWidget {
  final bool isOnline;
  final SessionModel? currentRequest;
  final VoidCallback onAcceptConnection;

  const AcceptUserScreen({
    super.key,
    required this.isOnline,
    this.currentRequest,
    required this.onAcceptConnection,
  });

  @override
  State<AcceptUserScreen> createState() => _AcceptUserScreenState();
}

class _AcceptUserScreenState extends State<AcceptUserScreen> {
  double _swipePosition = 0.0;
  final double _maxSwipeWidth = 260.0;
  int _secondsLeft = 30;
  Timer? _countdownTimer;
  bool _hasActiveRequest = false;

  int _paymentSecondsElapsed = 0;
  Timer? _paymentTimer;

  @override
  void initState() {
    super.initState();
    SessionController().addListener(_onSessionChanged);
    _checkForActiveRequest();
    _startTimer();
    if (SessionController().phase == SessionPhase.paymentPending) {
      _startPaymentTimer();
    }
  }

  void _checkForActiveRequest() {
    setState(() {
      _hasActiveRequest = widget.currentRequest != null && widget.currentRequest!.status == 'pending';
    });
  }

  void _startPaymentTimer() {
    _paymentTimer?.cancel();
    _paymentSecondsElapsed = 0;
    _paymentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (widget.currentRequest?.status != 'payment_pending') {
        timer.cancel();
        _paymentTimer = null;
        return;
      }
      setState(() {
        _paymentSecondsElapsed++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = remainingSeconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  void _onSessionChanged() {
    if (!mounted) return;

    setState(() {
      _hasActiveRequest = widget.currentRequest != null && widget.currentRequest!.status == 'pending';
    });

    if (widget.currentRequest?.status == 'payment_pending') {
      if (_paymentTimer == null) {
        _startPaymentTimer();
      }
    } else {
      _paymentTimer?.cancel();
      _paymentTimer = null;
    }

    // If payment succeeded → launch call for listener side
    if (widget.currentRequest?.status == 'active') {
      _launchCallAsListener();
    }

    // If seeker cancelled, reset the request card
    if (widget.currentRequest == null) {
      setState(() {
        _swipePosition = 0.0;
        _secondsLeft = 30;
      });
    }
  }

  void _launchCallAsListener() {
    if (!mounted || widget.currentRequest == null) return;
    
    final sessionTypeString = widget.currentRequest!.sessionType;
    Widget targetScreen;
    final partnerName = widget.currentRequest!.seekerMoniker;
    
    targetScreen = SessionChatScreen(
      sessionId: SessionController().currentSessionId ?? '',
      myUid: SessionController().firebaseUid ?? '',
      partnerName: partnerName,
      isSeeker: false,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    ).then((_) {
      // After returning from call, reset session
      SessionController().sessionCompleted();
    });
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _secondsLeft = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (!widget.isOnline) return;

      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        // Request expired — reset
        setState(() {
          _secondsLeft = 30;
          _swipePosition = 0.0;
        });
      }
    });
  }

  void _onListenerAccepts() {
    _countdownTimer?.cancel();
    if (widget.currentRequest != null) {
      SessionController().listenerAcceptsRequest('Listener', sessionId: widget.currentRequest!.id);
    }
    
    widget.onAcceptConnection();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _paymentTimer?.cancel();
    SessionController().removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AcceptUserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline && !oldWidget.isOnline) {
      _startTimer();
    }
    if (widget.currentRequest != oldWidget.currentRequest) {
      _onSessionChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOnline) {
      return _buildOfflineState();
    }
    if (widget.currentRequest?.status == 'payment_pending') {
      return _buildPaymentPendingBufferState();
    }
    if (widget.currentRequest?.status == 'pending') {
      return _buildActiveRequestView();
    }
    return _buildWaitingState();
  }

  Widget _buildPaymentPendingBufferState() {
    final isTherapist = SessionController().isTherapist;
    final brandColor = SafeTalkTheme.getListenerColor(isTherapist);
    final brandColorLight = SafeTalkTheme.getListenerColorLight(isTherapist);
    final seekerMoniker = widget.currentRequest?.seekerMoniker ?? 'Unknown Seeker';
    final moodTag = widget.currentRequest?.seekerMoodTag ?? 'Neutral';
    final sessionTypeString = widget.currentRequest?.sessionType ?? 'SessionType.messages';
    
    String sessionTypeName = 'Secure Chat';
    IconData sessionTypeIcon = Icons.chat_bubble_rounded;
    if (sessionTypeString == 'SessionType.voiceCall') {
      sessionTypeName = 'Secure Voice Call';
      sessionTypeIcon = Icons.phone_rounded;
    } else if (sessionTypeString == 'SessionType.videoCall') {
      sessionTypeName = 'Secure Video Call';
      sessionTypeIcon = Icons.videocam_rounded;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preparing Session',
            style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 28),
          ),
          const SizedBox(height: 6),
          Text(
            'The seeker is currently authorizing payment and connecting to your line...',
            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
          ),
          const SizedBox(height: 36),

          // Soothing buffer animation card
          Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                border: Border.all(color: brandColor.withValues(alpha: 0.3), width: 1.5),
                boxShadow: SafeTalkTheme.glowShadow(brandColor, opacity: 0.08),
              ),
              child: Column(
                children: [
                  // Breathing pulse with seeker visual style
                  const BreathingPulse(
                    size: 130,
                    showText: false,
                  ),
                  const SizedBox(height: 20),

                  // Elapsed stopwatch container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: SafeTalkTheme.bgForest,
                      borderRadius: SafeTalkTheme.pillRadius,
                      border: Border.all(color: brandColor.withValues(alpha: 0.15), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: brandColorLight),
                        const SizedBox(width: 8),
                        Text(
                          'Elapsed Time: ${_formatDuration(_paymentSecondsElapsed)}',
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(brandColorLight),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Awaiting checkout authorization...',
                        style: SafeTalkTheme.bodyStyle(color: brandColorLight, bold: true).copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Typically takes 10 - 20 seconds. Please keep this screen open.',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Match summary details card
          Text(
            'MATCH SPECIFICATIONS',
            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: SafeTalkTheme.glassCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatItem('Seeker Moniker', seekerMoniker),
                const SizedBox(height: 12),
                _buildStatItem('Mood Indicator', moodTag, highlightColor: SafeTalkTheme.brandTerracotta),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Medium', style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary)),
                    Row(
                      children: [
                        Icon(sessionTypeIcon, color: brandColorLight, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          sessionTypeName,
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action guidance block
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SafeTalkTheme.cardBg,
              borderRadius: SafeTalkTheme.standardRadius,
              border: Border.all(color: SafeTalkTheme.borderSage, width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.self_improvement_rounded, color: SafeTalkTheme.brandSageLight, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Preparation Tip: Take a slow breath, clear your thoughts, and prepare to hold a warm, empathetic, and confidential space.',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textPrimary).copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? highlightColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary)),
        Text(
          value,
          style: SafeTalkTheme.bodyStyle(
            color: highlightColor ?? SafeTalkTheme.textPrimary,
            bold: true,
          ),
        ),
      ],
    );
  }

  // ── OFFLINE ──────────────────────────────────────────────────────────────────

  Widget _buildOfflineState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SafeTalkTheme.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
              ),
              child: const Icon(Icons.nights_stay_outlined, color: SafeTalkTheme.textSecondary, size: 50),
            ),
            const SizedBox(height: 24),
            Text('Currently set to Offline', style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary)),
            const SizedBox(height: 10),
            Text(
              'Set your status to Online in the "Status" tab to begin receiving seeker match assignments.',
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── WAITING FOR REQUEST ───────────────────────────────────────────────────────

  Widget _buildWaitingState() {
    final isTherapist = SessionController().isTherapist;
    final brandColor = SafeTalkTheme.getListenerColor(isTherapist);
    final brandColorLight = SafeTalkTheme.getListenerColorLight(isTherapist);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Queue',
            style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 28),
          ),
          const SizedBox(height: 6),
          Text(
            'You are online and available. Waiting for a seeker to connect...',
            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
          ),
          const SizedBox(height: 48),
          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(color: SafeTalkTheme.borderSage, width: 2),
              ),
              child: Icon(Icons.hearing_rounded, color: brandColorLight, size: 56),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Listening Mode Active',
              style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'SafeTalk will show you incoming requests here when a seeker needs support.',
              textAlign: TextAlign.center,
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 32),
          // Simulate a demo request button for testing
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                // Randomly select one of the three session types (chat, voice, or video call)
                final random = Random();
                final sessionType = SessionType.values[random.nextInt(SessionType.values.length)];
                
                // Show the active incoming request card on screen
                SessionController().seekerSendsRequest(
                  moniker: 'Pine Pebble #107',
                  moodTag: 'Anxious / Overwhelmed',
                  concern: 'Having deep anxiety regarding upcoming challenges. Need a calm, non-judgmental space to talk.',
                  sessionType: sessionType,
                );
                // Flag as simulated request to automatically complete payment once accepted by listener
                SessionController().isSimulated = true;
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: brandColorLight,
                side: BorderSide(color: brandColor.withValues(alpha: 0.3), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.pillRadius),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.flash_on_rounded, size: 18),
              label: Text(
                'Simulate Incoming Match Request (Random)',
                style: SafeTalkTheme.bodyStyle(color: brandColorLight, bold: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ACTIVE INCOMING REQUEST ───────────────────────────────────────────────────

  Widget _buildActiveRequestView() {
    final isTherapist = SessionController().isTherapist;
    final brandColor = SafeTalkTheme.getListenerColor(isTherapist);
    final brandColorLight = SafeTalkTheme.getListenerColorLight(isTherapist);
    final sessionTypeString = widget.currentRequest?.sessionType ?? 'SessionType.messages';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Queue',
            style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 28),
          ),
          const SizedBox(height: 6),
          Text(
            'Swipe the card below to accept and begin a confidential session.',
            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Incoming Connection',
                style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.12),
                  borderRadius: SafeTalkTheme.pillRadius,
                ),
                child: Text(
                  'HIGH MATCH',
                  style: SafeTalkTheme.captionStyle(color: brandColorLight)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: SafeTalkTheme.glassCardDecoration.copyWith(
              border: Border.all(color: brandColor.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seeker moniker header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.15),
                      child: const Icon(Icons.psychology, color: SafeTalkTheme.brandTerracotta, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.currentRequest?.seekerMoniker ?? 'Unknown Seeker',
                            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                          ),
                          Text(
                            '97% Compatibility Match',
                            style: SafeTalkTheme.captionStyle(color: brandColorLight),
                          ),
                        ],
                      ),
                    ),
                    // Countdown timer
                    SizedBox(
                      height: 36,
                      width: 36,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _secondsLeft / 30,
                            strokeWidth: 3,
                            backgroundColor: SafeTalkTheme.bgMidnight,
                            valueColor: const AlwaysStoppedAnimation<Color>(SafeTalkTheme.brandTerracotta),
                          ),
                          Text(
                            '$_secondsLeft',
                            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textPrimary)
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(color: SafeTalkTheme.borderSage, height: 1),
                const SizedBox(height: 20),

                // Mood tag
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      Text(
                        'SEEKER MOOD:  ',
                        style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: SafeTalkTheme.bgMidnight,
                          borderRadius: SafeTalkTheme.pillRadius,
                          border: Border.all(color: SafeTalkTheme.borderSage, width: 1),
                        ),
                        child: Text(
                          widget.currentRequest?.seekerMoodTag ?? 'Neutral',
                          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandTerracotta)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "What's on their mind:",
                  style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  '"${widget.currentRequest?.seekerConcern ?? ''}"',
                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary)
                      .copyWith(fontStyle: FontStyle.italic, fontSize: 14, height: 1.4),
                ),

                const SizedBox(height: 28),

                // Session details
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.05),
                    borderRadius: SafeTalkTheme.standardRadius,
                    border: Border.all(color: SafeTalkTheme.borderSage),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSessionDetailChip(
                        sessionTypeString == 'SessionType.messages'
                            ? Icons.chat_bubble_outline_rounded
                            : (sessionTypeString == 'SessionType.videoCall'
                                ? Icons.videocam_outlined
                                : Icons.phone_outlined),
                        sessionTypeString == 'SessionType.messages'
                            ? 'Messages'
                            : (sessionTypeString == 'SessionType.videoCall'
                                ? 'Video Call'
                                : 'Voice Call'),
                      ),
                      _buildSessionDetailChip(
                        Icons.timer_outlined,
                        sessionTypeString == 'SessionType.videoCall' ? '7 mins' : '10 mins',
                      ),
                      _buildSessionDetailChip(
                        Icons.currency_rupee_rounded,
                        '₹150 standard',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Swipe to Accept slider
                Center(
                  child: Container(
                    height: 54,
                    width: _maxSwipeWidth,
                    decoration: BoxDecoration(
                      color: SafeTalkTheme.bgMidnight,
                      borderRadius: SafeTalkTheme.pillRadius,
                      border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Opacity(
                            opacity: (1 - (_swipePosition / (_maxSwipeWidth - 54))).clamp(0.2, 1.0),
                            child: Text(
                              'Swipe to listen →',
                              style: SafeTalkTheme.bodyStyle(
                                color: brandColorLight,
                                bold: true,
                              ).copyWith(fontSize: 14),
                            ),
                          ),
                        ),
                        Positioned(
                          left: _swipePosition,
                          top: 2,
                          bottom: 2,
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              setState(() {
                                _swipePosition += details.delta.dx;
                                if (_swipePosition < 0) _swipePosition = 0;
                                if (_swipePosition > _maxSwipeWidth - 52) {
                                  _swipePosition = _maxSwipeWidth - 52;
                                }
                              });
                            },
                            onHorizontalDragEnd: (details) {
                              if (_swipePosition >= _maxSwipeWidth - 64) {
                                _onListenerAccepts();
                              } else {
                                setState(() => _swipePosition = 0.0);
                              }
                            },
                            child: Container(
                              width: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: brandColor,
                              ),
                              child: const Center(
                                child: Icon(Icons.chevron_right_rounded, color: SafeTalkTheme.bgMidnight, size: 26),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Decline button
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      if (widget.currentRequest != null) {
                        SessionController().listenerDeclinesRequest(sessionId: widget.currentRequest!.id);
                      }
                      setState(() => _swipePosition = 0.0);
                    },
                    icon: const Icon(Icons.close_rounded, size: 16, color: SafeTalkTheme.brandTerracotta),
                    label: Text(
                      'Decline this request',
                      style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandTerracotta)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetailChip(IconData icon, String label) {
    final isTherapist = SessionController().isTherapist;
    final brandColorLight = SafeTalkTheme.getListenerColorLight(isTherapist);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: brandColorLight, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
