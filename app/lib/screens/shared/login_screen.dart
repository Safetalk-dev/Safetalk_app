import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/safetalk_logo.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  
  // Toggle between Sign In (false) and Sign Up (true)
  bool _isSigningUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _handleAccess() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnack('Please enter a valid email address.');
      return;
    }

    if (_passController.text.trim().isEmpty) {
      _showSnack('Please enter your security access key.');
      return;
    }

    setState(() => _isLoading = true);

    String? error;

    if (_isSigningUp) {
      // Sign Up with Firebase
      error = await AuthService().signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
    } else {
      // Sign In with Firebase
      error = await AuthService().signInWithEmail(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showSnack(error);
    }
    // If successful, AuthWrapper's StreamBuilder will automatically rebuild and navigate
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final error = await AuthService().signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showSnack(error);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight),
        ),
        backgroundColor: SafeTalkTheme.brandTerracotta,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = SafeTalkTheme.brandSage;

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
                      const SizedBox(height: 40),
                      
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
                      
                      const SizedBox(height: 40),

                      // Full Screen Panel Form Layout
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSigningUp ? 'Create an Account' : 'Welcome Back',
                            style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSigningUp
                                ? 'Register your secure email to create a confidential access key.'
                                : 'Sign in to access your secure haven.',
                            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                          ),
                          const SizedBox(height: 32),
                          
                          // Email Field
                          Text(
                            'CONFIDENTIAL EMAIL ADDRESS',
                            style: SafeTalkTheme.captionStyle(color: themeColor).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _emailController,
                            enabled: !_isLoading,
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
                              disabledBorder: OutlineInputBorder(
                                borderRadius: SafeTalkTheme.standardRadius,
                                borderSide: BorderSide(color: SafeTalkTheme.borderSage.withValues(alpha: 0.5), width: 1.5),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),

                          // Password Field
                          Text(
                            _isSigningUp ? 'CREATE ACCESS PIN' : 'ACCESS KEY',
                            style: SafeTalkTheme.captionStyle(color: themeColor).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _passController,
                            obscureText: _obscurePassword,
                            enabled: !_isLoading,
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
                              disabledBorder: OutlineInputBorder(
                                borderRadius: SafeTalkTheme.standardRadius,
                                borderSide: BorderSide(color: SafeTalkTheme.borderSage.withValues(alpha: 0.5), width: 1.5),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),

                          // Main Action Button (Sign In / Sign Up) with loading state
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAccess,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: SafeTalkTheme.bgMidnight,
                                disabledBackgroundColor: themeColor.withValues(alpha: 0.5),
                                elevation: 6,
                                shadowColor: themeColor.withValues(alpha: 0.15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: SafeTalkTheme.organicCardRadius,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(SafeTalkTheme.bgMidnight),
                                      ),
                                    )
                                  : Text(
                                      _isSigningUp ? 'Create Account' : 'Sign In',
                                      style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true)
                                          .copyWith(fontSize: 16),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Google Sign-In Button ──────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: SafeTalkTheme.textPrimary,
                                side: BorderSide(
                                  color: _isLoading 
                                      ? SafeTalkTheme.borderSage.withValues(alpha: 0.5) 
                                      : SafeTalkTheme.borderSage, 
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: SafeTalkTheme.organicCardRadius,
                                ),
                              ),
                              icon: _isLoading
                                  ? const SizedBox.shrink()
                                  : const Icon(Icons.g_mobiledata_rounded, size: 28),
                              label: Text(
                                'Continue with Google',
                                style: SafeTalkTheme.bodyStyle(
                                  color: _isLoading 
                                      ? SafeTalkTheme.textMuted 
                                      : SafeTalkTheme.textPrimary, 
                                  bold: true,
                                ).copyWith(fontSize: 15),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Route link switching between Sign In and Sign Up
                          Center(
                            child: InkWell(
                              onTap: _isLoading
                                  ? null
                                  : () {
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
                                      : 'New to SafeTalk? Sign Up',
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
                      'Firebase Secure Authentication',
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
