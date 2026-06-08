import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/safety_report_dialog.dart';

class ListenerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> listener;
  final bool isRegular;
  final Function(String name) onToggleRegular;
  final VoidCallback onMessage;
  final VoidCallback onConnectNow;
  final VoidCallback onBack;

  const ListenerDetailScreen({
    super.key,
    required this.listener,
    required this.isRegular,
    required this.onToggleRegular,
    required this.onMessage,
    required this.onConnectNow,
    required this.onBack,
  });

  @override
  State<ListenerDetailScreen> createState() => _ListenerDetailScreenState();
}

class _ListenerDetailScreenState extends State<ListenerDetailScreen> {
  late bool _isRegularLocal;

  @override
  void initState() {
    super.initState();
    _isRegularLocal = widget.isRegular;
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = widget.listener['avatarColor'] as Color? ?? SafeTalkTheme.brandSage;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: SafeTalkTheme.ambientBackground,
        child: SafeArea(
          child: Column(
            children: [
              // Top Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: SafeTalkTheme.textPrimary, size: 20),
                      onPressed: widget.onBack,
                    ),
                    const Spacer(),
                    Text(
                      'Listener Profile',
                      style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 18),
                    ),
                    const Spacer(),
                    // Heart/Regular Action indicator
                    IconButton(
                      icon: Icon(
                        _isRegularLocal ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: SafeTalkTheme.brandTerracotta,
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          _isRegularLocal = !_isRegularLocal;
                        });
                        widget.onToggleRegular(widget.listener['name']);
                        // Show quick confirmation toast
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isRegularLocal 
                                  ? 'Added ${widget.listener['name']} to Safe Circle'
                                  : 'Removed ${widget.listener['name']} from Safe Circle',
                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight),
                            ),
                            backgroundColor: SafeTalkTheme.brandTerracotta,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Scrollable detailed profile page
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Centered Hero Header Avatar
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: widget.listener['active'] == true
                                          ? SafeTalkTheme.brandSage
                                          : SafeTalkTheme.borderSage,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 54,
                                    backgroundColor: avatarColor.withValues(alpha: 0.18),
                                    child: Text(
                                      widget.listener['name'][0],
                                      style: SafeTalkTheme.displayStyle(color: avatarColor).copyWith(fontSize: 48),
                                    ),
                                  ),
                                ),
                                // Online indicator
                                Container(
                                  height: 24,
                                  width: 24,
                                  decoration: BoxDecoration(
                                    color: widget.listener['active'] == true
                                        ? SafeTalkTheme.brandSage
                                        : SafeTalkTheme.textMuted,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: SafeTalkTheme.bgMidnight, width: 3.5),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      widget.listener['active'] == true ? Icons.check : Icons.circle_outlined,
                                      color: SafeTalkTheme.bgMidnight,
                                      size: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              widget.listener['name'],
                              style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 26),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star_rounded, color: SafeTalkTheme.brandGold, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  widget.listener['rating'],
                                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandGold, bold: true)
                                      .copyWith(fontSize: 16),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  height: 4,
                                  width: 4,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: SafeTalkTheme.textMuted),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${widget.listener['sessions'] ?? 10} sessions completed',
                                  style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandSageLight),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Anonymity Shield Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                          border: Border.all(color: SafeTalkTheme.brandSage.withValues(alpha: 0.25), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: SafeTalkTheme.brandSage, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Confidential connection guaranteed. This listener is trained in peer support boundaries.',
                                style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Specialties List (Dynamic, Horizontally Scrollable)
                      Text(
                        'Empathetic Specialties',
                        style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: (widget.listener['specialties'] as List<String>).map((spec) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: SafeTalkTheme.bgMidnight,
                                  borderRadius: SafeTalkTheme.pillRadius,
                                  border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
                                ),
                                child: Text(
                                  spec,
                                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandSageLight).copyWith(fontSize: 12.5),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Biography Section
                      Text(
                        'Counselor Biography',
                        style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: SafeTalkTheme.glassCardDecoration,
                        child: Text(
                          widget.listener['bio'],
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary)
                              .copyWith(fontSize: 14.5, height: 1.5),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Mark as Regular Toggle Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isRegularLocal = !_isRegularLocal;
                            });
                            widget.onToggleRegular(widget.listener['name']);
                            // Show quick confirmation toast
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isRegularLocal 
                                      ? 'Added ${widget.listener['name']} to Safe Circle'
                                      : 'Removed ${widget.listener['name']} from Safe Circle',
                                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight),
                                ),
                                backgroundColor: SafeTalkTheme.brandTerracotta,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRegularLocal ? SafeTalkTheme.bgMidnight : SafeTalkTheme.brandTerracotta,
                            foregroundColor: _isRegularLocal ? SafeTalkTheme.brandTerracotta : SafeTalkTheme.bgMidnight,
                            elevation: 0,
                            side: const BorderSide(
                              color: SafeTalkTheme.brandTerracotta,
                              width: 1.5,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: SafeTalkTheme.organicCardRadius,
                            ),
                          ),
                          icon: Icon(
                            _isRegularLocal ? Icons.remove_circle_outline_rounded : Icons.favorite_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _isRegularLocal ? 'Remove from My Safe Circle' : 'Mark as Regular Companion',
                            style: SafeTalkTheme.bodyStyle(
                              color: _isRegularLocal ? SafeTalkTheme.brandTerracotta : SafeTalkTheme.bgMidnight,
                              bold: true,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Message and Connect Actions
                      // Connect Action
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: widget.onConnectNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SafeTalkTheme.brandSage,
                            foregroundColor: SafeTalkTheme.bgMidnight,
                            shape: const RoundedRectangleBorder(
                              borderRadius: SafeTalkTheme.organicCardRadius,
                            ),
                            elevation: 4,
                            shadowColor: SafeTalkTheme.brandSage.withValues(alpha: 0.2),
                          ),
                          child: Text(
                            'Connect Now',
                            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => _showReportDialog(context),
                          icon: const Icon(Icons.flag_outlined, color: SafeTalkTheme.brandGold, size: 18),
                          label: Text(
                            'Report this Companion',
                            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandGold, bold: true)
                                .copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CONFIDENTIAL COMPANION REPORT DIALOG ---
  void _showReportDialog(BuildContext context) {
    SafetyReportDialog.show(
      context: context,
      targetName: widget.listener['name'],
      isReportingListener: true,
      onSubmit: (reason, details) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Confidential report submitted. Thank you for helping keep SafeTalk secure.',
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
            ),
            backgroundColor: SafeTalkTheme.brandGold,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
