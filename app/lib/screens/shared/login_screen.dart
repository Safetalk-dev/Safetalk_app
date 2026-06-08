import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/safetalk_logo.dart';
import '../../controllers/session_controller.dart';

class LoginScreen extends StatefulWidget {
  final String activeRole;
  final VoidCallback onBack;
  final Function(String role) onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.activeRole,
    required this.onBack,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _monikerController = TextEditingController(); // For Sign Up custom handle
  bool _obscurePassword = true;
  
  // Toggle between Sign In (false) and Sign Up (true)
  bool _isSigningUp = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passController.dispose();
    _monikerController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    if (widget.activeRole == 'listener') {
      final email = _emailController.text.toLowerCase();
      final hasTherapist = email.contains('therapist');
      if (hasTherapist != SessionController().isTherapist) {
        setState(() {
          SessionController().isTherapist = hasTherapist;
        });
      }
    }
  }

  void _handleAccess() {
    if (_emailController.text.trim().isEmpty) {
      _showSnack('Please enter a valid email address.');
      return;
    }

    if (_passController.text.trim().isEmpty) {
      _showSnack('Please enter your security access key.');
      return;
    }

    if (_isSigningUp && _monikerController.text.trim().isEmpty) {
      _showSnack('Please choose a confidential handle.');
      return;
    }

    if (widget.activeRole == 'listener') {
      final email = _emailController.text.trim().toLowerCase();
      SessionController().isTherapist = email.contains('therapist');
    }

    // Success login/signup bypass
    widget.onLoginSuccess(widget.activeRole);
  }

  void _showSnack(String message) {
    final isTherapist = SessionController().isTherapist;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight),
        ),
        backgroundColor: widget.activeRole == 'user'
            ? SafeTalkTheme.brandTerracotta
            : SafeTalkTheme.getListenerColor(isTherapist),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTherapist = SessionController().isTherapist;
    final themeColor = widget.activeRole == 'user'
        ? SafeTalkTheme.brandTerracotta
        : SafeTalkTheme.getListenerColor(isTherapist);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: SafeTalkTheme.ambientBackground,
        child: SafeArea(
          child: Column(
            children: [
              // 1. Scrollable Content Area
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top header with Back Button
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: SafeTalkTheme.textPrimary, size: 20),
                            onPressed: widget.onBack,
                          ),
                          const Spacer(),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Small custom S Logo and Title
                      const SafeTalkLogo(size: 64, animate: true),
                      const SizedBox(height: 12),
                      Text(
                        'safe talk',
                        style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(
                          fontSize: 26,
                          letterSpacing: -1.0,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      
                      const SizedBox(height: 28),

                      // Full Screen Panel Form Layout
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSigningUp
                                ? (widget.activeRole == 'user' ? 'Create Seeker Haven' : 'Register Counselor Desk')
                                : (widget.activeRole == 'user' ? 'Welcome, Seeker' : 'Welcome, Peer Support'),
                            style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSigningUp
                                ? 'Register your secure email to create a custom confidential access key.'
                                : 'Sign in to access your secure local counseling logs.',
                            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                          ),
                          const SizedBox(height: 32),
                          
                          // --- NEW MONIKER FIELD (ONLY IN SIGN UP MODE) ---
                          if (_isSigningUp) ...[
                            Text(
                              widget.activeRole == 'user' ? 'CONFIDENTIAL MONIKER' : 'COUNSELOR RANK / Moniker',
                              style: SafeTalkTheme.captionStyle(color: themeColor).copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _monikerController,
                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                              decoration: InputDecoration(
                                hintText: widget.activeRole == 'user' ? 'e.g. Mist Pebble #482' : 'e.g. Listener Amber R.',
                                hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textMuted),
                                filled: true,
                                fillColor: SafeTalkTheme.bgMidnight,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: SafeTalkTheme.standardRadius,
                                  borderSide: const BorderSide(color: SafeTalkTheme.borderSage, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: SafeTalkTheme.standardRadius,
                                  borderSide: BorderSide(color: themeColor, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Email Field
                          Text(
                            'CONFIDENTIAL EMAIL ADDRESS',
                            style: SafeTalkTheme.captionStyle(color: themeColor).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _emailController,
                            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'name@safetalk.space',
                              hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textMuted),
                              filled: true,
                              fillColor: SafeTalkTheme.bgMidnight,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: SafeTalkTheme.standardRadius,
                                borderSide: const BorderSide(color: SafeTalkTheme.borderSage, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: SafeTalkTheme.standardRadius,
                                borderSide: BorderSide(color: themeColor, width: 2),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),

                          // Password Field
                          Text(
                            _isSigningUp ? 'CREATE ACCESS PIN' : (widget.activeRole == 'user' ? 'ACCESS KEY' : 'SECURITY PIN'),
                            style: SafeTalkTheme.captionStyle(color: themeColor).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _passController,
                            obscureText: _obscurePassword,
                            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textMuted),
                              filled: true,
                              fillColor: SafeTalkTheme.bgMidnight,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: SafeTalkTheme.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: SafeTalkTheme.standardRadius,
                                borderSide: const BorderSide(color: SafeTalkTheme.borderSage, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: SafeTalkTheme.standardRadius,
                                borderSide: BorderSide(color: themeColor, width: 2),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),

                          // Main Action Button (Sign In / Sign Up)
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _handleAccess,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: SafeTalkTheme.bgMidnight,
                                elevation: 6,
                                shadowColor: themeColor.withValues(alpha: 0.15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: SafeTalkTheme.organicCardRadius,
                                ),
                              ),
                              child: Text(
                                _isSigningUp
                                    ? (widget.activeRole == 'user' ? 'Create Free Sanctuary' : 'Register Credentials')
                                    : (widget.activeRole == 'user' ? 'Connect to Safe Harbor' : 'Go Online Now'),
                                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true)
                                    .copyWith(fontSize: 16),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Route link switching between Sign In and Sign Up
                          Center(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isSigningUp = !_isSigningUp;
                                });
                              },
                              borderRadius: SafeTalkTheme.pillRadius,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Text(
                                  _isSigningUp
                                      ? 'Already registered? Sign In instead'
                                      : 'New to SafeTalk? Create a safe key (Sign Up)',
                                  style: SafeTalkTheme.captionStyle(color: themeColor).copyWith(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // 2. Encryption active message fixed strictly at the bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, color: SafeTalkTheme.brandSageLight.withValues(alpha: 0.6), size: 15),
                    const SizedBox(width: 8),
                    Text(
                      'Decentralized Encryption Active',
                      style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
