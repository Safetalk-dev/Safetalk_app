import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/breathing_pulse.dart';
import '../../widgets/haptic_touchable.dart';
import '../../controllers/session_controller.dart';
import '../../services/razorpay_service.dart';

class RequestListenerScreen extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(String matchedListenerName) onMatched;

  const RequestListenerScreen({
    super.key,
    required this.onCancel,
    required this.onMatched,
  });

  @override
  State<RequestListenerScreen> createState() => _RequestListenerScreenState();
}

class _RequestListenerScreenState extends State<RequestListenerScreen> {
  int _currentStep = 0;
  Timer? _matchingTimer;
  bool _matchFound = false;

  String _selectedPaymentMethod = 'Razorpay';
  bool _isProcessingPayment = false;
  String _processingMessage = '';
  final TextEditingController _upiController = TextEditingController();

  // Razorpay overlay states
  bool _isRazorpayActive = false;
  String _razorpayStep = 'menu';
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();

  final List<String> _matchingSteps = [
    'Finding an active companion...',
    'Sending call request to matched companion...',
    'Companion received request. Awaiting acceptance...',
    'Companion agreed and accepted your request! ✅',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize platform-safe Razorpay module
    RazorpayService().initialize(
      onSuccess: _handleRazorpaySuccess,
      onFailure: _handleRazorpayFailure,
    );

    // Trigger session request on the shared controller (so listener side sees it)
    SessionController().seekerSendsRequest(
      moniker: 'Pine Pebble #107',
      moodTag: 'Anxious / Overwhelmed',
      concern: 'Having deep anxiety regarding upcoming challenges. Need a calm, non-judgmental space to talk.',
      sessionType: SessionController().sessionType,
    );

    // Listen for listener acceptance → jump straight to payment
    SessionController().addListener(_onSessionChanged);

    // Progress through "Searching" steps with timed animation
    _matchingTimer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (!mounted) return;
      if (_matchFound) {
        timer.cancel();
        return;
      }
      if (_currentStep < _matchingSteps.length - 2) {
        setState(() {
          _currentStep++;
        });
      }
    });
  }

  void _onSessionChanged() {
    if (!mounted) return;
    final phase = SessionController().phase;

    // Listener just accepted → jump to payment UI
    if (phase == SessionPhase.paymentPending && !_matchFound) {
      setState(() {
        _currentStep = _matchingSteps.length - 1;
        _matchFound = true;
      });
      _matchingTimer?.cancel();
    } else if (phase == SessionPhase.idle && !_matchFound) {
      // Session was rejected or cancelled
      _matchingTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No listeners are available right now. Please try again later.'),
          backgroundColor: SafeTalkTheme.brandTerracotta,
        ),
      );
      widget.onCancel();
    }
  }

  @override
  void dispose() {
    _matchingTimer?.cancel();
    SessionController().removeListener(_onSessionChanged);
    _upiController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    RazorpayService().dispose();
    super.dispose();
  }

  void _handleRazorpaySuccess(String paymentId) {
    if (!mounted) return;
    setState(() {
      _isRazorpayActive = false;
      _isProcessingPayment = true;
      _processingMessage = 'Payment authorized by Razorpay. Connecting to session...';
    });
    
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      SessionController().paymentSucceeded();
      final listenerName = SessionController().listenerName.isNotEmpty
          ? SessionController().listenerName
          : 'Listener';
      widget.onMatched(listenerName);
    });
  }

  void _handleRazorpayFailure(String code, String message) {
    if (!mounted) return;
    setState(() {
      _isRazorpayActive = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed ($code): $message', style: SafeTalkTheme.bodyStyle(color: Colors.white)),
        backgroundColor: SafeTalkTheme.brandTerracotta,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  Widget _buildPaymentProcessingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const BreathingPulse(size: 140, showText: false),
            const SizedBox(height: 36),
            Text(
              'Secure Payment Gateway Active',
              style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _processingMessage,
              textAlign: TextAlign.center,
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandSageLight).copyWith(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'Please do not close the app or lock your screen.',
              style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String id, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == id;
    return HapticTouchable(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: SafeTalkTheme.glassCardDecoration.copyWith(
          border: Border.all(
            color: isSelected ? SafeTalkTheme.brandSage : SafeTalkTheme.borderSage,
            width: 1.5,
          ),
          color: isSelected ? SafeTalkTheme.brandSage.withValues(alpha: 0.06) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? SafeTalkTheme.brandSage : SafeTalkTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: SafeTalkTheme.bodyStyle(
                  color: isSelected ? SafeTalkTheme.brandSage : SafeTalkTheme.textPrimary,
                  bold: isSelected,
                ).copyWith(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMainContent(context),
        if (_isRazorpayActive)
          Positioned.fill(child: _buildRazorpayOverlay()),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    if (_isProcessingPayment) {
      return _buildPaymentProcessingView();
    }

    // ── PAYMENT SCREEN (after listener accepts) ─────────────────────────────
    if (_matchFound) {
      final matchedListenerName = SessionController().listenerName.isNotEmpty
          ? SessionController().listenerName
          : 'Listener';

      return Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Match confirmed badge
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SafeTalkTheme.brandSage.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: SafeTalkTheme.brandSage,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Companion Matched!',
                style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 26),
              ),
              const SizedBox(height: 6),
              Text(
                'Your companion is ready. Complete payment to begin.',
                textAlign: TextAlign.center,
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              // Companion info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: SafeTalkTheme.glassCardDecoration,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: SafeTalkTheme.brandSage.withValues(alpha: 0.15),
                      child: const Icon(Icons.face_retouching_natural_rounded, color: SafeTalkTheme.brandSage, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            matchedListenerName,
                            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Certified Empathetic Peer Specialist',
                            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandSageLight),
                          ),
                        ],
                      ),
                    ),
                    // Online pulsing dot
                    Container(
                      height: 10,
                      width: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SafeTalkTheme.brandSage,
                        boxShadow: SafeTalkTheme.glowShadow(SafeTalkTheme.brandSage, opacity: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Session invoice card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                  border: Border.all(color: SafeTalkTheme.brandSage.withValues(alpha: 0.2), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIMED SESSION INVOICE',
                      style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Session Duration', style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary)),
                        Text(
                          SessionController().sessionType == SessionType.videoCall
                              ? '7 Minutes'
                              : '10 Minutes',
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Session Rate', style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary)),
                        Text('₹150 / Session', style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: SafeTalkTheme.borderSage, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: SafeTalkTheme.brandSageLight, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Payment processed securely via Razorpay (RBI Compliant)',
                            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment method header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SELECT PAYMENT METHOD',
                  style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Payment method options
              _buildPaymentMethodCard('Razorpay', 'Razorpay Gateway (Powered)', Icons.verified_user_rounded),

              const SizedBox(height: 32),

              // Pay & Start Session CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: HapticTouchable(
                  onTap: () {
                    if (RazorpayService().isNativeSupported) {
                      // Trigger real Razorpay Native sheet on Mobile
                      RazorpayService().openCheckout(
                        amountInRupees: 150,
                        description: 'SafeTalk Peer Support Session',
                        userEmail: 'seeker@safetalk.org',
                        userPhone: '9999999999',
                        sessionId: SessionController().currentSessionId ?? 'mock_session_id',
                      );
                    } else {
                      // Trigger simulated overlay on Desktop/Web
                      setState(() {
                        _isRazorpayActive = true;
                        _razorpayStep = 'menu';
                      });
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: SafeTalkTheme.brandSage,
                      borderRadius: SafeTalkTheme.organicCardRadius,
                      boxShadow: SafeTalkTheme.glowShadow(SafeTalkTheme.brandSage, opacity: 0.3),
                    ),
                    child: Text(
                      'Pay ₹150 via Razorpay & Start Session',
                      style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  _handleRazorpaySuccess('PAY-DEMOBYPASS-999');
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: SafeTalkTheme.organicCardRadius,
                    border: Border.all(color: SafeTalkTheme.brandSage.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Text(
                    '⚡ Demo Bypass (Skip Payment)',
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandSage, bold: true).copyWith(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  SessionController().seekerCancelsRequest();
                  widget.onCancel();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: SafeTalkTheme.brandTerracotta,
                  side: BorderSide(color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.4), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.pillRadius),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                child: Text(
                  'Cancel Session',
                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandTerracotta, bold: true),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── SEARCHING SCREEN (before listener accepts) ──────────────────────────
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Safe harbor badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: SafeTalkTheme.brandSage.withValues(alpha: 0.1),
                borderRadius: SafeTalkTheme.pillRadius,
                border: Border.all(color: SafeTalkTheme.brandSage.withValues(alpha: 0.3), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user, color: SafeTalkTheme.brandSage, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'SAFE HARBOR MATCH',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandSage)
                        .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const BreathingPulse(size: 140, showText: false),
            const SizedBox(height: 28),

            // Step indicator card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: SafeTalkTheme.glassCardDecoration,
              child: Column(
                children: [
                  Text(
                    'Finding a Companion...',
                    style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Average wait time is under 1 minute',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    children: List.generate(_matchingSteps.length, (index) {
                      final isActive = index == _currentStep;
                      final isCompleted = index < _currentStep;

                      Color stepColor = SafeTalkTheme.textMuted;
                      Widget stepLeading = Container(
                        height: 16,
                        width: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
                        ),
                      );

                      if (isActive) {
                        stepColor = SafeTalkTheme.brandTerracotta;
                        stepLeading = const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(SafeTalkTheme.brandTerracotta),
                          ),
                        );
                      } else if (isCompleted) {
                        stepColor = SafeTalkTheme.brandSage;
                        stepLeading = const Icon(Icons.check_circle, color: SafeTalkTheme.brandSage, size: 18);
                      }

                      return Padding(
                        key: ValueKey('step_$index'),
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            stepLeading,
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _matchingSteps[index],
                                style: SafeTalkTheme.bodyStyle(color: stepColor, bold: isActive).copyWith(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            OutlinedButton(
              onPressed: () {
                SessionController().seekerCancelsRequest();
                widget.onCancel();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: SafeTalkTheme.brandTerracotta,
                side: BorderSide(color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.4), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.pillRadius),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: Text(
                'Cancel Request',
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandTerracotta, bold: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── RAZORPAY OVERLAY ────────────────────────────────────────────────────────

  Widget _buildRazorpayOverlay() {
    return Container(
      color: const Color(0xFF0C101A).withValues(alpha: 0.95),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF131926),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24, spreadRadius: 4)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.payment_rounded, color: Color(0xFF3B82F6), size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Razorpay Secure',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                        onPressed: () => setState(() {
                          _isRazorpayActive = false;
                          _razorpayStep = 'menu';
                        }),
                      ),
                    ],
                  ),
                ),
                // Amount row
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SafeTalk Care Sessions', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            SessionController().sessionType == SessionType.videoCall
                                ? '7min_session_ref'
                                : '10min_session_ref',
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                      Text(
                        '₹150.00',
                        style: SafeTalkTheme.headingStyle(color: const Color(0xFF3B82F6))
                            .copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF1E293B), height: 1),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildRazorpayStepContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRazorpayStepContent() {
    switch (_razorpayStep) {
      case 'menu': return _buildRazorpayMenu();
      case 'card': return _buildRazorpayCardInput();
      case 'upi': return _buildRazorpayUpiInput();
      case 'success': return _buildRazorpaySuccess();
      default: return _buildRazorpayMenu();
    }
  }

  Widget _buildRazorpayMenu() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        key: const ValueKey('rp_menu'),
        children: [
          const Text(
            'PREFERRED PAYMENT METHOD',
            style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          _buildRazorpayOptionRow('Cards', 'Visa, Mastercard, RuPay, Maestro', Icons.credit_card_rounded, () {
            setState(() => _razorpayStep = 'card');
          }),
          const SizedBox(height: 8),
          _buildRazorpayOptionRow('UPI / QR', 'Google Pay, PhonePe, Paytm, BHIM', Icons.qr_code_rounded, () {
            setState(() => _razorpayStep = 'upi');
          }),
          const SizedBox(height: 8),
          _buildRazorpayOptionRow('Netbanking', 'All Indian major banks supported', Icons.account_balance_rounded, () {
            _simulateRazorpaySuccess();
          }),
          const SizedBox(height: 16),
          const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, color: Colors.white24, size: 12),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Razorpay Trusted Security • PCI-DSS Compliant',
                    style: TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRazorpayOptionRow(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF3B82F6), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white30),
          ],
        ),
      ),
    );
  }

  Widget _buildRazorpayCardInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        key: const ValueKey('rp_card'),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _razorpayStep = 'menu'),
              ),
              const SizedBox(width: 8),
              const Text(
                'PAY VIA CREDIT/DEBIT CARD',
                style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRazorpayTextField(_cardNumberController, 'Card Number', '4111 1111 1111 1111', keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRazorpayTextField(_cardExpiryController, 'Expiry', 'MM / YY', keyboardType: TextInputType.datetime),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRazorpayTextField(_cardCvvController, 'CVV', '•••', isObscured: true, keyboardType: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_cardNumberController.text.isEmpty || _cardExpiryController.text.isEmpty || _cardCvvController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all card details to authorize')),
                );
                return;
              }
              _simulateRazorpaySuccess();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Pay ₹150.00 Safely', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRazorpayTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool isObscured = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscured,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRazorpayUpiInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        key: const ValueKey('rp_upi'),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _razorpayStep = 'menu'),
              ),
              const SizedBox(width: 8),
              const Text(
                'PAY VIA UPI ID',
                style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRazorpayTextField(_upiController, 'UPI Virtual Private Address (VPA)', 'yourname@upi'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_upiController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid UPI VPA')),
                );
                return;
              }
              _simulateRazorpaySuccess();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Pay ₹150.00 Safely', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRazorpaySuccess() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        key: ValueKey('rp_success'),
        children: [
          SizedBox(
            height: 50,
            width: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Authorizing Payment with Razorpay...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Verifying transaction & launching session...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _simulateRazorpaySuccess() {
    setState(() => _razorpayStep = 'success');
    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _isRazorpayActive = false;
        _razorpayStep = 'menu';
        _isProcessingPayment = true;
        _processingMessage = 'Payment authorized by Razorpay. Connecting to session...';
      });
      // Notify session controller → listener side gets call too
      Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        SessionController().paymentSucceeded();
        final listenerName = SessionController().listenerName.isNotEmpty
            ? SessionController().listenerName
            : 'Listener';
        widget.onMatched(listenerName);
      });
    });
  }
}
