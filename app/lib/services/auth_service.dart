import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// AuthService is the single source of truth for all Firebase Authentication
/// operations in SafeTalk.
///
/// This singleton wraps FirebaseAuth and GoogleSignIn to provide a clean API
/// for sign-up, sign-in, Google OAuth, and sign-out flows.
class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '124622276181-2n4dn9nln4c3p90qof67dsij13bv7vtv.apps.googleusercontent.com',
  );

  // ── Getters ─────────────────────────────────────────────────────────────────

  /// The currently authenticated Firebase user, or null if signed out.
  User? get currentUser => _auth.currentUser;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => _auth.currentUser != null;

  /// Reactive stream of auth state changes. Use with StreamBuilder for
  /// automatic UI updates when the user signs in or out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The display name of the current user (moniker).
  String get displayName => _auth.currentUser?.displayName ?? 'Anonymous';

  /// The email of the current user.
  String get email => _auth.currentUser?.email ?? '';

  /// The Firebase UID of the current user.
  String get uid => _auth.currentUser?.uid ?? '';

  // ── Email/Password Authentication ───────────────────────────────────────────

  /// Create a new account with email and password.
  /// Returns null on success, or an error message string on failure.
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e.code, e.message);
    } on PlatformException catch (e) {
      return _mapFirebaseError(e.code, e.message);
    } catch (e) {
      return _mapFromErrorString(e.toString());
    }
  }

  /// Sign in with an existing email and password.
  /// Returns null on success, or an error message string on failure.
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e.code, e.message);
    } on PlatformException catch (e) {
      return _mapFirebaseError(e.code, e.message);
    } catch (e) {
      return _mapFromErrorString(e.toString());
    }
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────────

  /// Initiates the Google Sign-In flow.
  ///
  /// Returns null when the user is signed in successfully OR when the user
  /// cancels the sign-in flow (e.g. dismisses the account picker) — in both
  /// cases there is nothing for the UI to report as an error. Returns a
  /// non-null, user-displayable error message string on an actual failure.
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in flow — not an error, nothing to report.
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        return 'Could not retrieve Google authentication credentials. Please check your network and Google Play Services.';
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e.code, e.message);
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_failed' || (e.message?.contains('10') ?? false)) {
        return 'Google sign-in configuration error (Code 10). Please ensure SHA-1 fingerprint is registered in Firebase Console.';
      }
      return _mapFirebaseError(e.code, e.message);
    } catch (e) {
      if (e.toString().contains('MissingPlugin')) {
        return 'Google Sign-In is not supported on this platform.';
      }
      debugPrint('Google sign-in failed: ${e.toString()}');
      return 'Google sign-in failed. Please try again.';
    }
  }

  // ── Password Reset ──────────────────────────────────────────────────────────

  /// Sends a password reset email to [email].
  /// Returns null on success, or an error message string on failure.
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e.code, e.message);
    } catch (e) {
      return 'Could not send reset email. Please try again.';
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────────────────

  /// Signs out from Firebase Auth and Google Sign-In.
  Future<void> signOut() async {
    // Google Sign-In is not available on all platforms (e.g. Windows desktop),
    // so we catch the MissingPluginException gracefully.
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Platform doesn't support Google Sign-In — skip silently
    }
    await _auth.signOut();
  }

  // ── Update Profile ──────────────────────────────────────────────────────────

  /// Updates the display name (moniker) of the current user.
  Future<void> updateDisplayName(String newName) async {
    await _auth.currentUser?.updateDisplayName(newName.trim());
    await _auth.currentUser?.reload();
  }

  // ── Error Mapping ───────────────────────────────────────────────────────────

  /// Maps Firebase Auth error codes to user-friendly messages.
  String _mapFirebaseError(String code, String? message) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS': // Common generic error returned now
        return 'Incorrect email or password. Please try again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return message ?? 'Authentication failed. Please try again.';
    }
  }

  /// Parses generic exception strings to extract Firebase error codes if present.
  String _mapFromErrorString(String errorString) {
    if (errorString.contains('INVALID_LOGIN_CREDENTIALS') || 
        errorString.contains('invalid-credential') ||
        errorString.contains('wrong-password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (errorString.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (errorString.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    return 'An unexpected error occurred: $errorString';
  }
}
