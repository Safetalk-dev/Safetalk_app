import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../services/vault_service.dart';
import '../services/offline_chat_service.dart';

class ChatController extends ChangeNotifier {
  // Singleton instance
  static final ChatController _instance = ChatController._internal();
  factory ChatController() => _instance;
  ChatController._internal() {
    initializeOfflineChats();
  }

  // --- SEEKER THREADS (USER SIDE) ---
  final List<Map<String, dynamic>> userThreads = [];

  // --- LISTENER THREADS (LISTENER SIDE) ---
  final List<Map<String, dynamic>> listenerThreads = [];

  // PIN used to encrypt/decrypt listener notes
  String? _userPin;
  String? get userPin => _userPin;

  bool get isVaultEnabled => VaultService().isVaultInitialized();

  // --- OFFLINE PERSISTENCE HELPERS ---

  Future<void> initializeOfflineChats() async {
    try {
      final savedUserThreads = await OfflineChatService().loadUserThreads();
      if (savedUserThreads.isNotEmpty) {
        userThreads.clear();
        userThreads.addAll(savedUserThreads);
      }

      final savedListenerThreads = await OfflineChatService().loadListenerThreads();
      if (savedListenerThreads.isNotEmpty) {
        listenerThreads.clear();
        listenerThreads.addAll(savedListenerThreads);

        // Security-First: Wipe in-memory notes if Vault is active but not unlocked yet!
        if (isVaultEnabled && _userPin == null) {
          for (final t in listenerThreads) {
            t['notes'] = '';
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading offline chats: $e');
    }
  }

  void _persistUserThreads() {
    OfflineChatService().saveUserThreads(userThreads);
  }

  void _persistListenerThreads() {
    // Security-First: Strip notes when saving listener threads to keep them secure in Vault only!
    final cleanThreads = listenerThreads.map((t) {
      final copy = Map<String, dynamic>.from(t);
      copy['notes'] = ''; // Ensure notes are not written to unencrypted JSON
      return copy;
    }).toList();
    OfflineChatService().saveListenerThreads(cleanThreads);
  }

  Future<bool> unlockVault(String pin) async {
    try {
      final decryptedNotes = await VaultService().unlockVault(pin);
      _userPin = pin;
      
      // Load notes back into memory threads!
      for (final thread in listenerThreads) {
        final threadName = thread['name'];
        if (decryptedNotes.containsKey(threadName)) {
          thread['notes'] = decryptedNotes[threadName];
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void lockVault() {
    _userPin = null;
    // Clear notes from active memory to keep it absolutely zero-trace!
    for (final thread in listenerThreads) {
      thread['notes'] = '';
    }
    notifyListeners();
  }

  Future<void> enableVault(String pin) async {
    await VaultService().initializeVault(pin);
    _userPin = pin;
    
    // Save current memory notes into the vault!
    final notesMap = <String, String>{};
    for (final t in listenerThreads) {
      notesMap[t['name']] = t['notes'] ?? '';
    }
    await VaultService().saveNotes(pin, notesMap);
    
    notifyListeners();
  }

  Future<void> wipeAndResetVault() async {
    await VaultService().wipeAndResetVault();
    _userPin = null;
    
    // Clear all memory notes!
    for (final t in listenerThreads) {
      t['notes'] = '';
    }
    
    // Wipe offline stored chats as well
    await OfflineChatService().clearAllChats();
    
    // Reset lists to empty defaults
    userThreads.clear();
    listenerThreads.clear();
    
    notifyListeners();
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      await VaultService().changePin(oldPin, newPin);
      _userPin = newPin;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- ACTIONS FOR SEEKER SIDE ---

  /// Ensures a chat thread exists for the given listener name.
  /// Creates a new thread if one doesn't exist (e.g. first-time message).
  void ensureUserThread(String listenerName, {Color? avatarColor}) {
    final exists = userThreads.any((t) => t['name'] == listenerName);
    if (!exists) {
      userThreads.add({
        'name': listenerName,
        'status': 'New connection',
        'avatarColor': avatarColor ?? SafeTalkTheme.brandSage,
        'online': true,
        'unread': false,
        'lastMessage': 'Say hello! Your conversation is private and encrypted.',
        'time': 'Now',
        'messages': [
          {
            'sender': 'listener',
            'text': 'Hello, I am here for you. Take your time and share whatever feels comfortable.',
          }
        ],
      });
      _persistUserThreads();
      notifyListeners();
    }
  }

  void sendUserMessage(String partnerName, String message, {required VoidCallback onReplyTriggered}) {
    ensureUserThread(partnerName);
    final thread = userThreads.firstWhere((t) => t['name'] == partnerName);
    thread['messages'].add({'sender': 'user', 'text': message});
    thread['lastMessage'] = message;
    thread['time'] = 'Just now';
    _persistUserThreads();
    notifyListeners();

    // Trigger mock supportive automatic answer
    Future.delayed(const Duration(seconds: 2), () {
      final t = userThreads.firstWhere((t) => t['name'] == partnerName);
      String supportReply = "I am right here with you. What does your body feel like right now?";
      if (message.toLowerCase().contains('thank')) {
        supportReply = "Of course. You deserve to be heard. I'm glad to be here.";
      }
      t['messages'].add({'sender': 'listener', 'text': supportReply});
      t['lastMessage'] = supportReply;
      t['time'] = 'Just now';
      _persistUserThreads();
      notifyListeners();
      onReplyTriggered();
    });
  }

  void markUserThreadRead(String partnerName) {
    ensureUserThread(partnerName);
    final thread = userThreads.firstWhere((t) => t['name'] == partnerName);
    thread['unread'] = false;
    _persistUserThreads();
    notifyListeners();
  }

  void saveUserNotes(String partnerName, String notes) {
    final thread = userThreads.firstWhere((t) => t['name'] == partnerName);
    thread['notes'] = notes;
    _persistUserThreads();
    notifyListeners();
  }

  // --- ACTIONS FOR LISTENER SIDE ---
  void sendListenerMessage(String partnerName, String message) {
    final thread = listenerThreads.firstWhere((t) => t['name'] == partnerName);
    thread['messages'].add({'sender': 'listener', 'text': message});
    thread['lastMessage'] = message;
    thread['time'] = 'Just now';
    _persistListenerThreads();
    notifyListeners();
  }

  void sendListenerMacro(String partnerName, String macroText) {
    sendListenerMessage(partnerName, macroText);
  }

  void saveListenerNotes(String partnerName, String notes) {
    final thread = listenerThreads.firstWhere((t) => t['name'] == partnerName);
    thread['notes'] = notes;
    
    if (_userPin != null) {
      final notesMap = <String, String>{};
      for (final t in listenerThreads) {
        notesMap[t['name']] = t['notes'] ?? '';
      }
      VaultService().saveNotes(_userPin!, notesMap);
    }
    
    notifyListeners();
  }

  void markListenerThreadRead(String partnerName) {
    final thread = listenerThreads.firstWhere((t) => t['name'] == partnerName);
    thread['unread'] = false;
    _persistListenerThreads();
    notifyListeners();
  }
}
