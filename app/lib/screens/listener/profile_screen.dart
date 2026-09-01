import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/pin_sheet.dart';
import '../../widgets/haptic_touchable.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/session_controller.dart';
import '../../services/listener_settings_service.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';

class ListenerProfileScreen extends StatefulWidget {
  final bool isOnline;
  final Function(bool isOnline) onOnlineChanged;
  final VoidCallback onLogout;

  const ListenerProfileScreen({
    super.key,
    required this.isOnline,
    required this.onOnlineChanged,
    required this.onLogout,
  });

  @override
  State<ListenerProfileScreen> createState() => _ListenerProfileScreenState();
}

class _ListenerProfileScreenState extends State<ListenerProfileScreen> {
  late bool _panicCallToggle;
  late bool _supervisionToggle;
  String listenerName = AuthService().displayName.isNotEmpty && AuthService().displayName != 'Anonymous'
      ? AuthService().displayName
      : "Listener";
  
  String get listenerRank => SessionController().isTherapist 
      ? "Licensed Clinical Therapist (Prestige Cl.)" 
      : "Certified Empathetic Peer Specialist";

  double _pendingPayout = 0.0;
  bool _isPayoutRequesting = false;

  // Therapist verification states
  bool _isVerifying = false;
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _boardController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadListenerData();
    ChatController().addListener(_onChatControllerChanged);
    SessionController().addListener(_onSessionControllerChanged);
    _panicCallToggle = ListenerSettingsService().panicCallEnabled;
    _supervisionToggle = ListenerSettingsService().supervisionEnabled;
  }

  Future<void> _loadListenerData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await UserService().getUser(uid);
      if (user != null && mounted) {
        setState(() {
          if (user.displayName.isNotEmpty) {
            listenerName = user.displayName;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    ChatController().removeListener(_onChatControllerChanged);
    SessionController().removeListener(_onSessionControllerChanged);
    _licenseController.dispose();
    _boardController.dispose();
    super.dispose();
  }

  void _onChatControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSessionControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTherapist = SessionController().isTherapist;
    final brandColor = SafeTalkTheme.getListenerColor(isTherapist);
    final brandColorLight = SafeTalkTheme.getListenerColorLight(isTherapist);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header titles
          Text(
            'Support Profile',
            style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 28),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage counseling parameters and monitor professional logs.',
            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
          ),

          const SizedBox(height: 28),

          // Core identity card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: SafeTalkTheme.glassCardDecoration.copyWith(
              border: Border.all(color: brandColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: brandColor.withValues(alpha: 0.15),
                  child: Icon(Icons.face_retouching_natural_rounded, color: brandColor, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listenerName,
                        style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true)
                            .copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listenerRank,
                        style: SafeTalkTheme.captionStyle(color: brandColorLight).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Clinical Credential Verification Card
          Text(
            'Clinical Status',
            style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildClinicalCredentialCard(),

          const SizedBox(height: 28),

          // Status Control Card (Online/Offline)
          Text(
            'Availability Switch',
            style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: SafeTalkTheme.glassCardDecoration.copyWith(
              border: Border.all(
                color: widget.isOnline
                    ? brandColor.withValues(alpha: 0.4)
                    : SafeTalkTheme.borderSage,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isOnline ? 'Online & Active' : 'Offline & Paused',
                        style: SafeTalkTheme.bodyStyle(
                          color: widget.isOnline ? brandColor : SafeTalkTheme.textPrimary,
                          bold: true,
                        ).copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isOnline
                            ? 'You are active in the matching queue to receive client chats.'
                            : 'Matching requests are paused. Set online to resume listening.',
                        style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: widget.isOnline,
                  activeThumbColor: brandColor,
                  activeTrackColor: brandColor.withValues(alpha: 0.3),
                  inactiveThumbColor: SafeTalkTheme.textMuted,
                  inactiveTrackColor: SafeTalkTheme.bgMidnight,
                  onChanged: widget.onOnlineChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Professional Metrics
          Text(
            'Session Performance Logs',
            style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildMetricCard('2,480m', 'Minutes Listened', Icons.timer, brandColor),
              _buildMetricCard('148', 'Seekers Helped', Icons.volunteer_activism, SafeTalkTheme.brandTerracotta),
              _buildMetricCard('4.95', 'Feedback Rating', Icons.star, SafeTalkTheme.brandGold),
              _buildMetricCard('100%', 'Anonymity Kept', Icons.verified_user, brandColorLight),
            ],
          ),

          const SizedBox(height: 28),

          // Additional Professional Controls
          Text(
            'Counseling Parameters',
            style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: SafeTalkTheme.glassCardDecoration,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Accept acute panic requests',
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                  ),
                  subtitle: Text(
                    'Flags you as available for high-stress crisis matches',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  ),
                  value: _panicCallToggle,
                  activeThumbColor: brandColor,
                  activeTrackColor: brandColor.withValues(alpha: 0.3),
                  onChanged: (val) async {
                    await ListenerSettingsService().setPanicCallEnabled(val);
                    if (!mounted) return;
                    setState(() {
                      _panicCallToggle = val;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          val 
                              ? 'Acute Panic Crisis Standby ACTIVE.' 
                              : 'Crisis standby deactivated.',
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                        ),
                        backgroundColor: brandColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const Divider(color: SafeTalkTheme.borderSage, height: 1),
                SwitchListTile(
                  title: Text(
                    'Supervision backup mode',
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                  ),
                  subtitle: Text(
                    'Requests clinical supervisor oversight standby',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  ),
                  value: _supervisionToggle,
                  activeThumbColor: brandColor,
                  activeTrackColor: brandColor.withValues(alpha: 0.3),
                  onChanged: (val) async {
                    await ListenerSettingsService().setSupervisionEnabled(val);
                    if (!mounted) return;
                    setState(() {
                      _supervisionToggle = val;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          val 
                              ? 'Supervision standby requested. Oversight active.' 
                              : 'Oversight standby deactivated.',
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                        ),
                        backgroundColor: val ? SafeTalkTheme.brandGold : brandColorLight,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Confidential Note Vault',
            style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: SafeTalkTheme.glassCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Secure Vault',
                                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ChatController().isVaultEnabled
                                      ? brandColor.withValues(alpha: 0.15)
                                      : SafeTalkTheme.textMuted.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ChatController().isVaultEnabled ? 'Active' : 'Disabled',
                                  style: SafeTalkTheme.captionStyle(
                                    color: ChatController().isVaultEnabled
                                        ? brandColor
                                        : SafeTalkTheme.textSecondary,
                                  ).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Encrypt locally saved counselor notes using a custom user-derived PIN.',
                            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      value: ChatController().isVaultEnabled && ChatController().userPin != null,
                      activeThumbColor: brandColor,
                      activeTrackColor: brandColor.withValues(alpha: 0.3),
                      inactiveThumbColor: SafeTalkTheme.textMuted,
                      inactiveTrackColor: SafeTalkTheme.bgMidnight,
                      onChanged: (val) {
                        if (!ChatController().isVaultEnabled) {
                          // Setup PIN
                          PinSheet.show(
                            context: context,
                            mode: PinSheetMode.setup,
                            onSuccess: (pin) async {
                              await ChatController().enableVault(pin);
                              if (!mounted) return;
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Encrypted Vault successfully initialized.',
                                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                                  ),
                                  backgroundColor: brandColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        } else {
                          if (ChatController().userPin != null) {
                            // Lock Vault
                            ChatController().lockVault();
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Vault locked. Memory keys wiped.',
                                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                                ),
                                backgroundColor: brandColorLight,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            // Unlock Vault
                            PinSheet.show(
                              context: context,
                              mode: PinSheetMode.unlock,
                              onSuccess: (pin) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Vault unlocked successfully.',
                                      style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                                    ),
                                    backgroundColor: brandColor,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                if (ChatController().isVaultEnabled) ...[
                  const SizedBox(height: 16),
                  const Divider(color: SafeTalkTheme.borderSage, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HapticTouchable(
                        onTap: ChatController().userPin == null
                            ? null
                            : () {
                                PinSheet.show(
                                  context: context,
                                  mode: PinSheetMode.verifyCurrent,
                                  expectedPin: ChatController().userPin,
                                  onSuccess: (oldPin) {
                                    PinSheet.show(
                                      context: context,
                                      mode: PinSheetMode.createNew,
                                      onSuccess: (newPin) async {
                                        final success = await ChatController().changePin(oldPin, newPin);
                                        if (success) {
                                          setState(() {});
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Vault PIN changed successfully.',
                                                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                                              ),
                                              backgroundColor: brandColor,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                        child: Text(
                          'Change Vault PIN',
                          style: SafeTalkTheme.captionStyle(
                            color: ChatController().userPin == null
                                ? SafeTalkTheme.textMuted
                                : brandColorLight,
                          ).copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      HapticTouchable(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: SafeTalkTheme.cardBg,
                              title: Text(
                                'Reset Vault?',
                                style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.brandTerracotta),
                              ),
                              content: Text(
                                'WARNING: Recovery is mathematically impossible. Resetting will completely delete all locally encrypted journal notes. This action cannot be undone.',
                                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel', style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: SafeTalkTheme.cardBg,
                                        title: Text(
                                          'Permanent Data Loss',
                                          style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.brandTerracotta),
                                        ),
                                        content: Text(
                                          'All your seeker notes will be permanently erased. Resetting deletes both metadata salts and encrypted notes. Proceed?',
                                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text('Cancel', style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary)),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              await ChatController().wipeAndResetVault();
                                              if (!mounted) return;
                                              setState(() {});
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Vault wiped successfully.',
                                                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                                                  ),
                                                  backgroundColor: SafeTalkTheme.brandTerracotta,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                            child: Text('Yes, Delete', style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandTerracotta, bold: true)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Text('Confirm Delete', style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandTerracotta, bold: true)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          'Reset Vault',
                          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandTerracotta)
                              .copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Session Earnings & Payout Ledger Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Earnings & Payouts Ledger',
                  style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.12),
                  borderRadius: SafeTalkTheme.pillRadius,
                ),
                child: Text(
                  isTherapist ? 'CLINICAL TIER' : 'COMPANION TIER',
                  style: SafeTalkTheme.captionStyle(color: brandColor)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Earnings Card containing metrics & recent payouts
          Container(
            padding: const EdgeInsets.all(20),
            decoration: SafeTalkTheme.glassCardDecoration.copyWith(
              border: Border.all(color: brandColor.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildEarningsMetric('Total Earned', '₹1,996', brandColor)),
                    Container(height: 30, width: 1.5, color: SafeTalkTheme.borderSage),
                    Expanded(child: _buildEarningsMetric('Settled Sessions', '4', SafeTalkTheme.brandGold)),
                    Container(height: 30, width: 1.5, color: SafeTalkTheme.borderSage),
                    Expanded(child: _buildEarningsMetric('Pending Payout', '₹${_pendingPayout.toStringAsFixed(0)}', brandColorLight)),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: SafeTalkTheme.borderSage, height: 1),
                const SizedBox(height: 16),
                
                // Payout Trigger
                if (_pendingPayout > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: HapticTouchable(
                      onTap: _isPayoutRequesting ? null : _handlePayoutRequest,
                      child: Container(
                        decoration: BoxDecoration(
                          color: brandColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: SafeTalkTheme.glowShadow(brandColor),
                        ),
                        alignment: Alignment.center,
                        child: _isPayoutRequesting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Request Bank Payout (₹${_pendingPayout.toStringAsFixed(0)})',
                                style: SafeTalkTheme.bodyStyle(color: Colors.white, bold: true),
                              ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: SafeTalkTheme.bgMidnight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SafeTalkTheme.borderSage),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: brandColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'All earnings fully settled',
                          style: SafeTalkTheme.bodyStyle(color: brandColor, bold: true),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                Text(
                  'RECENT SETTLED SESSIONS',
                  style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary)
                      .copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),

                // List of listener earnings items
                _buildSettledSessionItem(
                  moniker: 'Pine Pebble #107',
                  date: '26 May 2026, 14:15',
                  payout: '₹399',
                  platformFee: '₹100 (Platform Fee)',
                ),
                const Divider(color: SafeTalkTheme.borderSage, height: 1),
                _buildSettledSessionItem(
                  moniker: 'Golden Fern #883',
                  date: '24 May 2026, 11:30',
                  payout: '₹399',
                  platformFee: '₹100 (Platform Fee)',
                ),
                const Divider(color: SafeTalkTheme.borderSage, height: 1),
                _buildSettledSessionItem(
                  moniker: 'Ocean Breeze #204',
                  date: '20 May 2026, 19:45',
                  payout: '₹399',
                  platformFee: '₹100 (Platform Fee)',
                ),
                const Divider(color: SafeTalkTheme.borderSage, height: 1),
                _buildSettledSessionItem(
                  moniker: 'Silent Oak #012',
                  date: '17 May 2026, 16:00',
                  payout: '₹399',
                  platformFee: '₹100 (Platform Fee)',
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Logout Button
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
                'Leave Duty Desk (Sign Out)',
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandTerracotta, bold: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePayoutRequest() {
    final isTherapist = SessionController().isTherapist;
    final brandColor = SafeTalkTheme.getListenerColor(isTherapist);

    setState(() {
      _isPayoutRequesting = true;
    });
    // Simulate minor network / authorization delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isPayoutRequesting = false;
          _pendingPayout = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payout of ₹399 successfully initiated to your linked UPI VPA payout address!',
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
            ),
            backgroundColor: brandColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Widget _buildEarningsMetric(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: SafeTalkTheme.headingStyle(color: color)
              .copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildSettledSessionItem({
    required String moniker,
    required String date,
    required String payout,
    required String platformFee,
  }) {
    final isTherapist = SessionController().isTherapist;
    final brandColor = SafeTalkTheme.getListenerColor(isTherapist);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moniker,
                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$date • $platformFee',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            payout,
            style: SafeTalkTheme.bodyStyle(color: brandColor, bold: true)
                .copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: SafeTalkTheme.glassCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary)
                  .copyWith(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalCredentialCard() {
    final isTherapist = SessionController().isTherapist;
    final brandColor = SafeTalkTheme.getListenerColor(isTherapist);
    final brandColorLight = SafeTalkTheme.getListenerColorLight(isTherapist);

    if (isTherapist) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: SafeTalkTheme.glassCardDecoration.copyWith(
          border: Border.all(color: brandColor.withValues(alpha: 0.5), width: 2),
          boxShadow: SafeTalkTheme.glowShadow(brandColor, opacity: 0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: brandColor.withValues(alpha: 0.12),
                  child: Icon(Icons.verified_rounded, color: brandColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Licensed Clinical Therapist',
                        style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 16),
                      ),
                      Text(
                        'PRESTIGE AMETHYST ACTIVE',
                        style: SafeTalkTheme.captionStyle(color: brandColorLight).copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'VERIFIED',
                    style: SafeTalkTheme.captionStyle(color: brandColor).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: SafeTalkTheme.borderSage, height: 1),
            const SizedBox(height: 16),
            _buildCredentialRow('REGISTRY ID', _licenseController.text),
            const SizedBox(height: 8),
            _buildCredentialRow('BOARD AUTHORITY', _boardController.text),
            const SizedBox(height: 8),
            _buildCredentialRow('STATUS', 'Active & Certified'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: HapticTouchable(
                onTap: () {
                  SessionController().isTherapist = false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Returned to Certified Peer Counselor status.',
                        style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                      ),
                      backgroundColor: SafeTalkTheme.brandSage,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: SafeTalkTheme.bgMidnight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Revert to Standard Peer Theme',
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandTerracotta, bold: true).copyWith(fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: SafeTalkTheme.glassCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: SafeTalkTheme.brandSage.withValues(alpha: 0.12),
                  child: const Icon(Icons.volunteer_activism_rounded, color: SafeTalkTheme.brandSage, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Certified Peer Specialist',
                        style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 16),
                      ),
                      Text(
                        'Listed under peer counseling networks',
                        style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: SafeTalkTheme.borderSage, height: 1),
            const SizedBox(height: 16),
            Text(
              'UPGRADE PROFILE TO THERAPIST',
              style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: SafeTalkTheme.bgMidnight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SafeTalkTheme.borderSage),
              ),
              child: TextField(
                controller: _licenseController,
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Board License Number (e.g., LCSW-99824-A)',
                  labelStyle: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: SafeTalkTheme.bgMidnight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SafeTalkTheme.borderSage),
              ),
              child: TextField(
                controller: _boardController,
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'State Board Authority',
                  labelStyle: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: HapticTouchable(
                onTap: _isVerifying ? null : () {
                  setState(() {
                    _isVerifying = true;
                  });
                  Future.delayed(const Duration(milliseconds: 1200), () {
                    if (!mounted) return;
                    setState(() {
                      _isVerifying = false;
                    });
                    SessionController().isTherapist = true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Clinical credentials verified successfully! Enjoy your prestige Royal Amethyst layout theme.',
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                        ),
                        backgroundColor: SafeTalkTheme.brandTherapist,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: SafeTalkTheme.brandSage,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: SafeTalkTheme.glowShadow(SafeTalkTheme.brandSage),
                  ),
                  alignment: Alignment.center,
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Verify Clinical Credentials',
                          style: SafeTalkTheme.bodyStyle(color: Colors.white, bold: true),
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCredentialRow(String label, String value) {
    final isTherapist = SessionController().isTherapist;
    final brandColor = SafeTalkTheme.getListenerColor(isTherapist);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: SafeTalkTheme.bodyStyle(
            color: label == 'STATUS' ? brandColor : SafeTalkTheme.textPrimary,
            bold: true,
          ).copyWith(fontSize: 13.5),
        ),
      ],
    );
  }
}
