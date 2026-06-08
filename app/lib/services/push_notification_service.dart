import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal() {
    loadSettings();
  }

  bool _isEnabled = true;
  bool get isEnabled => _isEnabled;

  static const String _filename = 'push_notifications.json';

  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    await _saveSettings();
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
