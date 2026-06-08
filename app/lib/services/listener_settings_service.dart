import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class ListenerSettingsService {
  static final ListenerSettingsService _instance = ListenerSettingsService._internal();
  factory ListenerSettingsService() => _instance;
  ListenerSettingsService._internal() {
    loadSettings();
  }

  bool _panicCallEnabled = true;
  bool get panicCallEnabled => _panicCallEnabled;

  bool _supervisionEnabled = false;
  bool get supervisionEnabled => _supervisionEnabled;

  static const String _filename = 'listener_settings.json';

  Future<void> setPanicCallEnabled(bool value) async {
    _panicCallEnabled = value;
    await _saveSettings();
  }

  Future<void> setSupervisionEnabled(bool value) async {
    _supervisionEnabled = value;
    await _saveSettings();
  }

  Future<void> loadSettings() async {
    try {
      final file = File('data/$_filename');
      if (file.existsSync()) {
        final data = jsonDecode(await file.readAsString());
        _panicCallEnabled = data['panicCallEnabled'] ?? true;
        _supervisionEnabled = data['supervisionEnabled'] ?? false;
      }
    } catch (e) {
      debugPrint('Error loading listener settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final dir = Directory('data');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File('data/$_filename');
      await file.writeAsString(jsonEncode({
        'panicCallEnabled': _panicCallEnabled,
        'supervisionEnabled': _supervisionEnabled,
      }));
    } catch (e) {
      debugPrint('Error saving listener settings: $e');
    }
  }
}
