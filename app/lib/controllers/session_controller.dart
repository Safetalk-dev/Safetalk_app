import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/services/user_service.dart';
import 'dart:async';
import 'package:app/services/session_service.dart';
import 'package:app/models/session_model.dart';

/// SessionController acts as the single source of truth for a SafeTalk session.
///
/// In production, this state would be managed via a real-time backend (e.g., WebSocket,
/// Firebase Realtime DB) so that seeker and listener apps communicate independently.
///
/// In this demo, both the seeker UI and the listener UI run in the same app, so we use
/// a singleton ChangeNotifier to bridge the two sides seamlessly.
enum SessionType {
  messages,
  voiceCall,
  videoCall,
}

enum SessionPhase {
  idle,           // No active session
  seekerRequesting, // Seeker sent a request, waiting for listener
  listenerIncoming, // Listener is seeing the incoming request
  paymentPending, // Listener accepted, seeker must pay
  callActive,     // Payment confirmed, call in progress
  callEnded,      // Call concluded, show rating/summary
}

class SessionController extends ChangeNotifier {
  // Singleton
  static final SessionController _instance = SessionController._internal();
  factory SessionController() => _instance;
  SessionController._internal();

  // ── Firebase User Identity ────────────────────────────────────────────────
  String? _firebaseUid;
  String? _firebaseEmail;
  String? _firebaseDisplayName;
  String _currentRole = 'user'; // Defaults to user

  String? get firebaseUid => _firebaseUid;
  String? get firebaseEmail => _firebaseEmail;
  String? get firebaseDisplayName => _firebaseDisplayName;
  String get currentRole => _currentRole;

  /// Initialize session identity from the currently authenticated Firebase user.
  Future<void> initFromFirebaseUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firebaseUid = user.uid;
      _firebaseEmail = user.email;
      _firebaseDisplayName = user.displayName;

      // Fetch role from Firestore
      final userModel = await UserService().getUser(user.uid);
      if (userModel != null) {
        _currentRole = userModel.role;
        _isTherapist = userModel.role == 'therapist';
      }
      notifyListeners();
    }
  }

  /// Clear Firebase identity on sign-out.
  void clearFirebaseUser() {
    _firebaseUid = null;
    _firebaseEmail = null;
    _firebaseDisplayName = null;
    notifyListeners();
  }

  SessionPhase _phase = SessionPhase.idle;
  SessionPhase get phase => _phase;

  bool isSimulated = false;

  SessionType _sessionType = SessionType.voiceCall;
  SessionType get sessionType => _sessionType;
  set sessionType(SessionType val) {
    _sessionType = val;
    notifyListeners();
  }

  bool _isTherapist = false;
  bool get isTherapist => _isTherapist;
  set isTherapist(bool val) {
    _isTherapist = val;
    notifyListeners();
  }

  String _seekerMoniker = 'Pine Pebble #107';
  String get seekerMoniker => _seekerMoniker;

  String _listenerName = '';
  String get listenerName => _listenerName;

  String _seekerMoodTag = 'Anxious / Overwhelmed';
  String get seekerMoodTag => _seekerMoodTag;

  String _seekerConcern = 'Having deep anxiety regarding upcoming exams. Need a calm, non-judgmental space to talk.';
  String get seekerConcern => _seekerConcern;

  // Payment amount in rupees (₹150 for Razorpay)
  final int sessionAmount = 150;

  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  StreamSubscription<SessionModel?>? _sessionSub;

  // ── Seeker Initiates ────────────────────────────────────────────────────────

  Future<void> seekerSendsRequest({
    required String moniker,
    required String moodTag,
    required String concern,
    required SessionType sessionType,
  }) async {
    isSimulated = false;
    _seekerMoniker = moniker;
    _seekerMoodTag = moodTag;
    _seekerConcern = concern;
    _sessionType = sessionType;
    _phase = SessionPhase.seekerRequesting;
    notifyListeners();

    if (_firebaseUid != null) {
      _currentSessionId = await SessionService().createSessionRequest(
        seekerId: _firebaseUid!,
        seekerMoniker: moniker,
        seekerMoodTag: moodTag,
        seekerConcern: concern,
        sessionType: sessionType.toString(),
      );
      
      _sessionSub?.cancel();
      _sessionSub = SessionService().streamSession(_currentSessionId!).listen((session) {
        if (session == null) return;
        
        if (session.status == 'payment_pending') {
          _phase = SessionPhase.paymentPending;
          _listenerName = session.listenerId ?? 'Matched Listener';
          notifyListeners();
        } else if (session.status == 'active') {
          _phase = SessionPhase.callActive;
          notifyListeners();
        } else if (session.status == 'completed') {
          _phase = SessionPhase.callEnded;
          notifyListeners();
        } else if (session.status == 'rejected' || session.status == 'cancelled') {
          _phase = SessionPhase.idle;
          notifyListeners();
        }
      });
    }
  }

  void seekerCancelsRequest() {
    isSimulated = false;
    _phase = SessionPhase.idle;
    _listenerName = '';
    if (_currentSessionId != null) {
      SessionService().cancelSession(_currentSessionId!);
      _sessionSub?.cancel();
      _currentSessionId = null;
    }
    notifyListeners();
  }

  // ── Listener Responds ───────────────────────────────────────────────────────

  void listenerAcceptsRequest(String acceptingListenerName, {String? sessionId}) {
    final targetId = sessionId ?? _currentSessionId;
    if (targetId != null) {
      SessionService().acceptSession(targetId);
      _currentSessionId = targetId; // Sync for listener side
    }
    _listenerName = acceptingListenerName;
    _phase = SessionPhase.paymentPending;
    notifyListeners();
  }

  void listenerDeclinesRequest({String? sessionId}) {
    final targetId = sessionId ?? _currentSessionId;
    if (targetId != null && _firebaseUid != null) {
      SessionService().rejectSession(targetId, _firebaseUid!);
    }
    _phase = SessionPhase.idle;
    notifyListeners();
  }

  // ── Payment ──────────────────────────────────────────────────────────────────

  void paymentSucceeded() {
    if (_currentSessionId != null) {
      SessionService().markPaymentComplete(_currentSessionId!);
    }
    _phase = SessionPhase.callActive;
    notifyListeners();
  }

  // ── Call ─────────────────────────────────────────────────────────────────────

  void callEnded() {
    _phase = SessionPhase.callEnded;
    notifyListeners();
  }

  void sessionCompleted() {
    isSimulated = false;
    _phase = SessionPhase.idle;
    _listenerName = '';
    if (_currentSessionId != null) {
      SessionService().endSession(_currentSessionId!);
      _sessionSub?.cancel();
      _currentSessionId = null;
    }
    notifyListeners();
  }
}
