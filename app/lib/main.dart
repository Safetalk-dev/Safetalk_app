import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'firebase_options.dart';
import 'theme/tokens.dart';
import 'screens/shared/auth_wrapper.dart';
import 'services/biometric_service.dart';
import 'services/push_notification_service.dart';
import 'services/listener_settings_service.dart';
import 'services/auth_service.dart';

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
  
  // Initialize Firebase before anything else
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Connect to local emulators in debug mode
  if (kDebugMode) {
    try {
      final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      
      // Connect Authentication
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      
      // Connect Firestore
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      
      // Connect Cloud Functions
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      
      debugPrint('Firebase Emulators connected successfully: Host=$host');
    } catch (e) {
      debugPrint('Error connecting to Firebase Emulators: $e');
    }
  }
  
  // Asynchronously load the service settings before the UI renders to prevent race conditions
  await BiometricService().loadSettings();
  await PushNotificationService().loadSettings();
  await ListenerSettingsService().loadSettings();
  
  runApp(const SafeTalkApp());
}

class SafeTalkApp extends StatelessWidget {
  const SafeTalkApp({super.key});

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
      home: BiometricShieldWrapper(
        child: AuthWrapper(
          onLogout: () => AuthService().signOut(),
        ),
      ),
    );
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
