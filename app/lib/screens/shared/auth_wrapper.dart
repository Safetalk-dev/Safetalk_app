import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/services/user_service.dart';
import 'package:app/models/user_model.dart';
import 'package:app/theme/tokens.dart';
import 'package:app/screens/shared/login_screen.dart';
import 'package:app/screens/shared/onboarding_screen.dart';
import 'package:app/screens/user/user_layout.dart';
import 'package:app/screens/listener/listener_layout.dart';

class AuthWrapper extends StatelessWidget {
  final VoidCallback onLogout;

  const AuthWrapper({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: SafeTalkTheme.bgMidnight,
            body: Center(
              child: CircularProgressIndicator(color: SafeTalkTheme.brandSage),
            ),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        return FutureBuilder<UserModel?>(
          future: UserService().getUser(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: SafeTalkTheme.bgMidnight,
                body: Center(
                  child: CircularProgressIndicator(color: SafeTalkTheme.brandSage),
                ),
              );
            }

            final userModel = userSnapshot.data;

            if (userModel == null) {
              // User exists in Auth but no Firestore document -> Needs Onboarding
              return OnboardingScreen(firebaseUser: user);
            }

            // Route based on role
            if (userModel.role == 'listener') {
              return ListenerLayout(onLogout: onLogout);
            } else {
              return UserLayout(onLogout: onLogout);
            }
          },
        );
      },
    );
  }
}
