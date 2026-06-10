import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  String? get firebaseUid => _firebaseUid;
  String? get firebaseEmail => _firebaseEmail;
  String? get firebaseDisplayName => _firebaseDisplayName;

  /// Initialize session identity from the currently authenticated Firebase user.
  void initFromFirebaseUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firebaseUid = user.uid;
      _firebaseEmail = user.email;
      _firebaseDisplayName = user.displayName;
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

  // ── Seeker Initiates ────────────────────────────────────────────────────────

  /// Called when the seeker taps "Connect Now" / "Request Listener".
  void seekerSendsRequest({
    required String moniker,
    required String moodTag,
    required String concern,
    required SessionType sessionType,
  }) {
    isSimulated = false; // Reset to false for normal seeker flow
    _seekerMoniker = moniker;
    _seekerMoodTag = moodTag;
    _seekerConcern = concern;
    _sessionType = sessionType;
    _phase = SessionPhase.seekerRequesting;
    notifyListeners();
  }

  /// Called when the seeker cancels the request before a match is made.
  void seekerCancelsRequest() {
    isSimulated = false;
    _phase = SessionPhase.idle;
    _listenerName = '';
    notifyListeners();
  }

  // ── Listener Responds ───────────────────────────────────────────────────────

  /// Called when the listener swipes to accept the incoming request.
  void listenerAcceptsRequest(String acceptingListenerName) {
    _listenerName = acceptingListenerName;
    _phase = SessionPhase.paymentPending;
    notifyListeners();
  }

  /// Called when the listener declines (skips) the incoming request.
  void listenerDeclinesRequest() {
    _phase = SessionPhase.idle;
    notifyListeners();
  }

  // ── Payment ──────────────────────────────────────────────────────────────────

  /// Called when the seeker completes payment successfully.
  void paymentSucceeded() {
    _phase = SessionPhase.callActive;
    notifyListeners();
  }

  // ── Call ─────────────────────────────────────────────────────────────────────

  /// Called when the call ends (either timer or manual hang-up).
  void callEnded() {
    _phase = SessionPhase.callEnded;
    notifyListeners();
  }

  /// Called after ratings are submitted or skipped — resets to idle.
  void sessionCompleted() {
    isSimulated = false;
    _phase = SessionPhase.idle;
    _listenerName = '';
    notifyListeners();
  }
}
