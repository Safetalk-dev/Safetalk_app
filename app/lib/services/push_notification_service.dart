import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal() {
    loadSettings();
  }

  bool _isEnabled = true;
  bool get isEnabled => _isEnabled;

  static const String _filename = 'push_notifications.json';

  /// Check if the platform natively supports Firebase Cloud Messaging SDK
  bool get _isFcmSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    await _saveSettings();
    if (_isFcmSupported) {
      if (value) {
        await FirebaseMessaging.instance.subscribeToTopic('all');
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic('all');
      }
    }
  }

  Future<void> loadSettings() async {
    try {
      final file = File('data/$_filename');
      if (file.existsSync()) {
        final data = jsonDecode(await file.readAsString());
        _isEnabled = data['enabled'] ?? true;
      }
    } catch (e) {
      debugPrint('Error loading push notification settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final dir = Directory('data');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File('data/$_filename');
      await file.writeAsString(jsonEncode({'enabled': _isEnabled}));
    } catch (e) {
      debugPrint('Error saving push notification settings: $e');
    }
  }

  /// Initialize FCM integration for Android & iOS mobile clients.
  /// Safely handles desktop/web fallback environments.
  Future<void> initialize(BuildContext context) async {
    if (!_isFcmSupported) {
      debugPrint('PushNotificationService: FCM is not natively supported on this platform. Seamless desktop fallback enabled.');
      return;
    }

    try {
      // 1. Request permission
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM: User granted push notification permission.');
        
        // 2. Fetch device token
        final token = await messaging.getToken();
        if (token != null) {
          debugPrint('FCM Registration Token: $token');
          await _saveTokenToDatabase(token);
        }

        // 3. Monitor token refresh
        messaging.onTokenRefresh.listen(_saveTokenToDatabase);

        // 4. Handle foreground notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('FCM: Received a foreground message: ${message.messageId}');
          if (message.notification != null) {
            showMockNotification(
              context,
              message.notification!.title ?? 'SafeTalk Alert',
              message.notification!.body ?? '',
            );
          }
        });

        // 5. Subscribe to global broadcasts
        if (_isEnabled) {
          await messaging.subscribeToTopic('all');
        }
      } else {
        debugPrint('FCM: User declined or has not accepted push permissions.');
      }
    } catch (e) {
      debugPrint('FCM: Failed to initialize messaging: $e');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenRefresh': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM: Token successfully registered to Firestore user profile.');
      } catch (e) {
        debugPrint('FCM: Failed to save token to database: $e');
      }
    }
  }

  /// Trigger a discreet mock notification SnackBar to demonstrate active status
  void showMockNotification(BuildContext context, String title, String body) {
    if (!_isEnabled) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF222C3D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Positioned neatly above the navigation bar
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
