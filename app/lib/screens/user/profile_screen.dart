import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/haptic_touchable.dart';
import '../../services/push_notification_service.dart';
import '../../services/biometric_service.dart';
import '../../services/auth_service.dart';

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
  final List<Map<String, dynamic>> _billingHistory = [];

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
                if (widget.moodScores.isEmpty)
                  Container(
                    height: 120,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: SafeTalkTheme.bgMidnight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.show_chart_rounded, color: SafeTalkTheme.textSecondary, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          'No daily check-ins recorded yet',
                          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Complete check-ins on Explore to track your trends',
                          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                else ...[
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
          _billingHistory.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                    border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined, color: SafeTalkTheme.textSecondary, size: 36),
                      const SizedBox(height: 10),
                      Text(
                        'No billing history yet',
                        style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your completed session receipts will appear here.',
                        style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                    border: Border.all(color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < _billingHistory.length; i++) ...[
                        if (i > 0) const Divider(color: SafeTalkTheme.borderSage, height: 1),
                        _buildBillingItem(
                          context,
                          listenerName: _billingHistory[i]['listenerName'] ?? '',
                          date: _billingHistory[i]['date'] ?? '',
                          status: _billingHistory[i]['status'] ?? 'Settled',
                          amount: _billingHistory[i]['amount'] ?? '',
                          method: _billingHistory[i]['method'] ?? 'UPI',
                          txnId: _billingHistory[i]['txnId'] ?? '',
                        ),
                      ],
                    ],
                  ),
                ),

          const SizedBox(height: 36),

          // Logout Action Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                await AuthService().signOut();
                widget.onLogout();
              },
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

    if (points.length == 1) {
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = points[0] >= 0.5 ? SafeTalkTheme.brandSage : SafeTalkTheme.brandTerracotta;
      canvas.drawCircle(Offset(size.width / 2, size.height * (1 - points[0])), 6, dotPaint);
      return;
    }

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
