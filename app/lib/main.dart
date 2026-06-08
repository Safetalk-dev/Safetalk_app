import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme/tokens.dart';
import 'screens/shared/welcome_screen.dart';
import 'screens/shared/login_screen.dart';
import 'screens/user/user_layout.dart';
import 'screens/listener/listener_layout.dart';
import 'services/biometric_service.dart';
import 'services/push_notification_service.dart';
import 'services/listener_settings_service.dart';

// Custom ScrollBehavior to enable global click-and-drag mouse scrolling for horizontal lists
class SafeTalkScrollBehavior extends MaterialScrollBehavior {
  const SafeTalkScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Asynchronously load the service settings before the UI renders to prevent race conditions
  await BiometricService().loadSettings();
  await PushNotificationService().loadSettings();
  await ListenerSettingsService().loadSettings();
  
  runApp(const SafeTalkApp());
}

class SafeTalkApp extends StatefulWidget {
  const SafeTalkApp({super.key});

  @override
  State<SafeTalkApp> createState() => _SafeTalkAppState();
}

class _SafeTalkAppState extends State<SafeTalkApp> {
  // Authentication states:
  // - null: Shows the tranquil, wordless Welcome/Landing screen
  // - 'user': Seeker App Experience
  // - 'listener': Peer support specialist Desk
  String? _currentUserRole;

  // Intermediate routing state:
  // Tracks which role the user clicked on the welcome screen
  String? _showingLoginForRole;

  void _selectRole(String role) {
    setState(() {
      _showingLoginForRole = role;
    });
  }

  void _cancelLoginSelection() {
    setState(() {
      _showingLoginForRole = null;
    });
  }

  void _login(String role) {
    setState(() {
      _currentUserRole = role;
      _showingLoginForRole = null;
    });
  }

  void _logout() {
    setState(() {
      _currentUserRole = null;
      _showingLoginForRole = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'safe talk',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const SafeTalkScrollBehavior(),
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: SafeTalkTheme.bgMidnight,
        primaryColor: SafeTalkTheme.brandSage,
        colorScheme: const ColorScheme.light(
          primary: SafeTalkTheme.brandSage,
          secondary: SafeTalkTheme.brandTerracotta,
          surface: SafeTalkTheme.cardBg,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: SafeTalkTheme.bgMidnight,
          elevation: 0,
          iconTheme: IconThemeData(color: SafeTalkTheme.textPrimary),
        ),
        useMaterial3: true,
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: _buildCurrentScreen(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    if (_currentUserRole == 'user') {
      return BiometricShieldWrapper(
        child: UserLayout(
          key: const ValueKey('user_layout'),
          onLogout: _logout,
        ),
      );
    } else if (_currentUserRole == 'listener') {
      return BiometricShieldWrapper(
        child: ListenerLayout(
          key: const ValueKey('listener_layout'),
          onLogout: _logout,
        ),
      );
    } else if (_showingLoginForRole != null) {
      return LoginScreen(
        key: ValueKey('login_screen_$_showingLoginForRole'),
        activeRole: _showingLoginForRole!,
        onBack: _cancelLoginSelection,
        onLoginSuccess: _login,
      );
    } else {
      return WelcomeScreen(
        key: const ValueKey('welcome_screen'),
        onRoleSelected: _selectRole,
      );
    }
  }
}

class BiometricShieldWrapper extends StatefulWidget {
  final Widget child;
  const BiometricShieldWrapper({super.key, required this.child});

  @override
  State<BiometricShieldWrapper> createState() => _BiometricShieldWrapperState();
}

class _BiometricShieldWrapperState extends State<BiometricShieldWrapper> {
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  void _checkAuthentication() async {
    if (BiometricService().isEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final success = await BiometricService().authenticate(
          context, 
          reason: 'Authenticate to access your Safe Haven.'
        );
        if (success) {
          setState(() {
            _authenticated = true;
          });
        }
      });
    } else {
      setState(() {
        _authenticated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authenticated && BiometricService().isEnabled) {
      return Scaffold(
        backgroundColor: SafeTalkTheme.bgMidnight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, color: SafeTalkTheme.brandTerracotta, size: 64),
              const SizedBox(height: 16),
              Text(
                'Safe Haven Locked',
                style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock with Biometrics to continue',
                style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SafeTalkTheme.brandTerracotta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _checkAuthentication,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Unlock'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _authenticated = true;
                  });
                },
                child: Text(
                  'Demo Bypass',
                  style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widget.child;
  }
}
