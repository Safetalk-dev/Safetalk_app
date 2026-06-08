import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal() {
    loadSettings();
  }

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  static const String _filename = 'biometrics.json';

  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    await _saveSettings();
  }

  Future<void> loadSettings() async {
    try {
      final file = File('data/$_filename');
      if (file.existsSync()) {
        final data = jsonDecode(await file.readAsString());
        _isEnabled = data['enabled'] ?? false;
      }
    } catch (e) {
      debugPrint('Error loading biometric settings: $e');
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
      debugPrint('Error saving biometric settings: $e');
    }
  }

  /// Launch biometric prompt to authenticate the user
  Future<bool> authenticate(BuildContext context, {required String reason}) async {
    if (!_isEnabled) return true; // Auto-pass if disabled

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BiometricAuthDialog(reason: reason),
    );
    return result ?? false;
  }
}

class _BiometricAuthDialog extends StatelessWidget {
  final String reason;
  const _BiometricAuthDialog({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE4E8F2), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C6C82C5),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fingerprint_rounded,
              color: Color(0xFF6C82C5),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Biometric Verification',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222C3D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5B6980),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5B6980),
                      side: const BorderSide(color: Color(0xFFE4E8F2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C82C5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Authenticate'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
