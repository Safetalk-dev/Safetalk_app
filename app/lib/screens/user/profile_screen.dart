import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/haptic_touchable.dart';
import '../../services/push_notification_service.dart';
import '../../services/biometric_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;
  final List<double> moodScores;
  final Function(String newUsername) onUsernameChanged;
  final VoidCallback onLogout;

  const UserProfileScreen({
    super.key,
    required this.username,
    required this.moodScores,
    required this.onUsernameChanged,
    required this.onLogout,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late bool _notificationToggle;
  late bool _pinLockToggle;
  
  // Username Edit States
  bool _isEditingUsername = false;
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _notificationToggle = PushNotificationService().isEnabled;
    _pinLockToggle = BiometricService().isEnabled;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _saveUsername() {
    if (_usernameController.text.trim().isNotEmpty) {
      widget.onUsernameChanged(_usernameController.text.trim());
      setState(() {
        _isEditingUsername = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Title
          Text(
            'My Safe Haven',
            style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 28),
          ),
          const SizedBox(height: 6),
          Text(
            'Control your anonymity credentials and view session trends.',
            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
          ),

          const SizedBox(height: 28),

          // Seeker Nickname Identifier Card (Now fully editable!)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: SafeTalkTheme.glassCardDecoration.copyWith(
              border: Border.all(
                color: _isEditingUsername ? SafeTalkTheme.brandTerracotta.withValues(alpha: 0.4) : SafeTalkTheme.borderSage,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.15),
                  child: const Icon(Icons.psychology, color: SafeTalkTheme.brandTerracotta, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ANONYMOUS ID',
                        style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandTerracotta)
                            .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      if (_isEditingUsername)
                        TextField(
                          controller: _usernameController,
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true)
                              .copyWith(fontSize: 18),
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Enter anonymous alias...',
                            hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textMuted),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _saveUsername(),
                        )
                      else
                        Text(
                          widget.username,
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true)
                              .copyWith(fontSize: 18),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isEditingUsername ? Icons.check_circle : Icons.edit_note_rounded,
                    color: SafeTalkTheme.brandTerracotta,
                  ),
                  tooltip: _isEditingUsername ? 'Save Moniker' : 'Edit Username',
                  onPressed: () {
                    if (_isEditingUsername) {
                      _saveUsername();
                    } else {
                      setState(() {
                        _isEditingUsername = true;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Mood Trend Title
          Text(
            'Inner Balance Tracker',
            style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
          ),
          const SizedBox(height: 12),

          // Premium Custom Painted Mood Chart Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: SafeTalkTheme.glassCardDecoration.copyWith(
              border: Border.all(color: SafeTalkTheme.brandSage.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Check-in Balance Trends',
                      style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: SafeTalkTheme.brandSage.withValues(alpha: 0.12),
                        borderRadius: SafeTalkTheme.pillRadius,
                      ),
                      child: Text(
                        'STABLE SAGE',
                        style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandSageLight)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Dynamic painted graph using layout's scores list
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: MoodChartPainter(points: widget.moodScores),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(SafeTalkTheme.brandTerracotta, '1 - 4 (Heavy/Anxious)'),
                      const SizedBox(width: 24),
                      _buildLegendItem(SafeTalkTheme.brandSage, '5 - 10 (Calm/Centered)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Settings Section
          Text(
            'Security & Controls',
            style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          
          Container(
            decoration: SafeTalkTheme.glassCardDecoration,
            child: Column(
              children: [
                // Switch 1
                SwitchListTile(
                  title: Text(
                    'Push notifications',
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                  ),
                  subtitle: Text(
                    'Receive discreet matching confirmations',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  ),
                  value: _notificationToggle,
                  activeThumbColor: SafeTalkTheme.brandTerracotta,
                  activeTrackColor: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.3),
                  inactiveThumbColor: SafeTalkTheme.textMuted,
                  inactiveTrackColor: SafeTalkTheme.bgMidnight,
                  onChanged: (val) async {
                    await PushNotificationService().setEnabled(val);
                    if (!mounted) return;
                    setState(() {
                      _notificationToggle = val;
                    });
                    if (val) {
                      PushNotificationService().showMockNotification(
                        context, 
                        'SafeTalk Shield Active', 
                        'Discreet matching confirmations are now operational.'
                      );
                    }
                  },
                ),
                const Divider(color: SafeTalkTheme.borderSage, height: 1),
                // Switch 2
                SwitchListTile(
                  title: Text(
                    'App biometric shield',
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                  ),
                  subtitle: Text(
                    'Requires passcode or fingerprint to open',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  ),
                  value: _pinLockToggle,
                  activeThumbColor: SafeTalkTheme.brandTerracotta,
                  activeTrackColor: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.3),
                  inactiveThumbColor: SafeTalkTheme.textMuted,
                  inactiveTrackColor: SafeTalkTheme.bgMidnight,
                  onChanged: (val) async {
                    if (val) {
                      // Request mock registration scan
                      final authenticated = await BiometricService().authenticate(
                        context, 
                        reason: 'Verify fingerprint to lock your Safe Haven.'
                      );
                      if (authenticated) {
                        await BiometricService().setEnabled(true);
                        if (!mounted) return;
                        setState(() {
                          _pinLockToggle = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Biometric authentication registered successfully.',
                              style: SafeTalkTheme.bodyStyle(color: Colors.white, bold: true),
                            ),
                            backgroundColor: SafeTalkTheme.brandTerracotta,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else {
                      await BiometricService().setEnabled(false);
                      setState(() {
                        _pinLockToggle = false;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Session Billing Ledger Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Session Billing Ledger',
                  style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.12),
                    borderRadius: SafeTalkTheme.pillRadius,
                  ),
                  child: Text(
                    '₹499/SESSION',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandTerracotta)
                        .copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ledger Card
          Container(
            decoration: SafeTalkTheme.glassCardDecoration.copyWith(
              border: Border.all(color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              children: [
                _buildBillingItem(
                  context,
                  listenerName: 'Listener Amber R.',
                  date: '26 May 2026',
                  status: 'Settled via Google Pay',
                  amount: '₹499',
                  method: 'Google Pay (UPI)',
                  txnId: 'ST-TXN-90281-GP',
                ),
                const Divider(color: SafeTalkTheme.borderSage, height: 1),
                _buildBillingItem(
                  context,
                  listenerName: 'Listener Sage P.',
                  date: '24 May 2026',
                  status: 'Settled via PhonePe',
                  amount: '₹499',
                  method: 'PhonePe (UPI)',
                  txnId: 'ST-TXN-88412-PP',
                ),
                const Divider(color: SafeTalkTheme.borderSage, height: 1),
                _buildBillingItem(
                  context,
                  listenerName: 'Listener Joy M.',
                  date: '19 May 2026',
                  status: 'Settled via Custom UPI VPA',
                  amount: '₹499',
                  method: 'UPI ID (safe@upi)',
                  txnId: 'ST-TXN-76192-UP',
                ),
                const Divider(color: SafeTalkTheme.borderSage, height: 1),
                _buildBillingItem(
                  context,
                  listenerName: 'Listener Harmony T.',
                  date: '15 May 2026',
                  status: 'Settled via Paytm',
                  amount: '₹499',
                  method: 'Paytm (UPI)',
                  txnId: 'ST-TXN-65103-PM',
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Logout Action Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: widget.onLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: SafeTalkTheme.brandTerracotta,
                side: const BorderSide(color: SafeTalkTheme.borderSage, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.organicCardRadius),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(
                'Leave Safe Haven (Sign Out)',
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandTerracotta, bold: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(
    BuildContext context, {
    required String listenerName,
    required String date,
    required String amount,
    required String status,
    required String method,
    required String txnId,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: SafeTalkTheme.glassCardDecoration.copyWith(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.3), width: 2),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Header
              Center(
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: SafeTalkTheme.brandTerracotta,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Session Receipt',
                  style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
                ),
              ),
              Center(
                child: Text(
                  'SafeTalk Session Settlement',
                  style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 20),
              
              // Dashed line
              Row(
                children: List.generate(
                  20,
                  (index) => Expanded(
                    child: Container(
                      color: index % 2 == 0 ? Colors.transparent : SafeTalkTheme.borderSage,
                      height: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Transaction Details Grid
              _buildReceiptRow('Transaction ID', txnId),
              const SizedBox(height: 8),
              _buildReceiptRow('Date & Time', date),
              const SizedBox(height: 8),
              _buildReceiptRow('Consultation Companion', listenerName),
              const SizedBox(height: 8),
              _buildReceiptRow('Session Length', '20 Minutes (Timed)'),
              const SizedBox(height: 8),
              _buildReceiptRow('Payment Method', method),
              const SizedBox(height: 8),
              _buildReceiptRow('Status', 'Success (Settled)', isStatus: true),
              
              const SizedBox(height: 20),
              Row(
                children: List.generate(
                  20,
                  (index) => Expanded(
                    child: Container(
                      color: index % 2 == 0 ? Colors.transparent : SafeTalkTheme.borderSage,
                      height: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Total Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL PAID',
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                  ),
                  Text(
                    amount,
                    style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.brandTerracotta)
                        .copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SafeTalkTheme.brandTerracotta,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: SafeTalkTheme.bodyStyle(color: Colors.white, bold: true),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: SafeTalkTheme.bodyStyle(
              color: isStatus ? SafeTalkTheme.brandSage : SafeTalkTheme.textPrimary,
              bold: isStatus,
            ).copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildBillingItem(
    BuildContext context, {
    required String listenerName,
    required String date,
    required String status,
    required String amount,
    required String method,
    required String txnId,
  }) {
    return HapticTouchable(
      onTap: () => _showReceiptDialog(
        context,
        listenerName: listenerName,
        date: date,
        amount: amount,
        status: status,
        method: method,
        txnId: txnId,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.1),
              child: const Icon(
                Icons.check_circle_rounded,
                color: SafeTalkTheme.brandTerracotta,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listenerName,
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$date • $status',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amount,
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true)
                  .copyWith(fontSize: 16),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: SafeTalkTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
        ),
      ],
    );
  }
}

// Custom Painter to draw a gorgeous organic-feeling mood curve dynamically
class MoodChartPainter extends CustomPainter {
  final List<double> points;

  MoodChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = SafeTalkTheme.bgMidnight
      ..style = PaintingStyle.fill;
    
    // Draw internal background box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      bgPaint,
    );

    // Draw horizontal reference guide lines
    final gridPaint = Paint()
      ..color = SafeTalkTheme.borderSage.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), gridPaint);

    if (points.isEmpty) return;

    final double stepX = size.width / (points.length - 1);
    
    final linePaint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    linePaint.shader = const LinearGradient(
      colors: [SafeTalkTheme.brandTerracotta, SafeTalkTheme.brandSage],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(rect);

    final path = Path();
    path.moveTo(0, size.height * (1 - points[0]));

    for (int i = 1; i < points.length; i++) {
      final double x = i * stepX;
      final double y = size.height * (1 - points[i]);
      
      final double prevX = (i - 1) * stepX;
      final double prevY = size.height * (1 - points[i - 1]);
      final double controlX = prevX + (stepX / 2);
      
      path.cubicTo(controlX, prevY, controlX, y, x, y);
    }

    canvas.drawPath(path, linePaint);

    // Draw circular dots
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i++) {
      final double x = i * stepX;
      final double y = size.height * (1 - points[i]);
      
      dotPaint.color = points[i] >= 0.5 ? SafeTalkTheme.brandSage : SafeTalkTheme.brandTerracotta;
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MoodChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
