import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class OfflineChatService {
  static final OfflineChatService _instance = OfflineChatService._internal();
  factory OfflineChatService() => _instance;
  OfflineChatService._internal();

  static const String _userChatsFilename = 'user_chats.json';
  static const String _listenerChatsFilename = 'listener_chats.json';

  /// Helper to get the correct path to save documents offline
  Future<File> _getFile(String filename) async {
    Directory directory;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Direct local workspace directory for desktop/dev environment
      directory = Directory('data');
    } else {
      // Standard mobile/sandbox application directory
      directory = await getApplicationDocumentsDirectory();
    }
    
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return File('${directory.path}/$filename');
  }

  /// Serialize a List of threads, transforming Color objects to ints for JSON safety
  String _serializeThreads(List<Map<String, dynamic>> threads) {
    final List<Map<String, dynamic>> jsonCompatibleThreads = threads.map((thread) {
      final copy = Map<String, dynamic>.from(thread);
      
      // Convert Color to int
      if (copy['avatarColor'] is Color) {
        copy['avatarColor'] = (copy['avatarColor'] as Color).toARGB32();
      }
      
      return copy;
    }).toList();

    return jsonEncode(jsonCompatibleThreads);
  }

  /// Deserialize a list of threads, converting int values back to Color objects
  List<Map<String, dynamic>> _deserializeThreads(String jsonString) {
    if (jsonString.isEmpty) return [];
    
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((item) {
      final thread = Map<String, dynamic>.from(item as Map);
      
      // Convert int back to Color
      if (thread['avatarColor'] is int) {
        thread['avatarColor'] = Color(thread['avatarColor'] as int);
      } else {
        // Fallback default color if missing
        thread['avatarColor'] = const Color(0xFF8FA89B);
      }
      
      // Ensure messages sublist is mutable Map list
      if (thread['messages'] != null) {
        thread['messages'] = (thread['messages'] as List)
            .map((msg) => Map<String, dynamic>.from(msg as Map))
            .toList();
      }
      
      return thread;
    }).toList();
  }

  /// Save Seeker/User chats to disk
  Future<void> saveUserThreads(List<Map<String, dynamic>> threads) async {
    try {
      final file = await _getFile(_userChatsFilename);
      final jsonCompatibleString = _serializeThreads(threads);
      await file.writeAsString(jsonCompatibleString);
    } catch (e) {
      debugPrint('Error saving user chats: $e');
    }
  }

  /// Load Seeker/User chats from disk
  Future<List<Map<String, dynamic>>> loadUserThreads() async {
    try {
      final file = await _getFile(_userChatsFilename);
      if (!file.existsSync()) return [];
      
      final contents = await file.readAsString();
      return _deserializeThreads(contents);
    } catch (e) {
      debugPrint('Error loading user chats: $e');
      return [];
    }
  }

  /// Save Listener/Peer chats to disk
  Future<void> saveListenerThreads(List<Map<String, dynamic>> threads) async {
    try {
      final file = await _getFile(_listenerChatsFilename);
      final jsonCompatibleString = _serializeThreads(threads);
      await file.writeAsString(jsonCompatibleString);
    } catch (e) {
      debugPrint('Error saving listener chats: $e');
    }
  }

  /// Load Listener/Peer chats from disk
  Future<List<Map<String, dynamic>>> loadListenerThreads() async {
    try {
      final file = await _getFile(_listenerChatsFilename);
      if (!file.existsSync()) return [];
      
      final contents = await file.readAsString();
      return _deserializeThreads(contents);
    } catch (e) {
      debugPrint('Error loading listener chats: $e');
      return [];
    }
  }

  /// Clear all local chats from file storage completely
  Future<void> clearAllChats() async {
    try {
      final userFile = await _getFile(_userChatsFilename);
      if (userFile.existsSync()) {
        await userFile.delete();
      }
      final listenerFile = await _getFile(_listenerChatsFilename);
      if (listenerFile.existsSync()) {
        await listenerFile.delete();
      }
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
    }
  }
}
