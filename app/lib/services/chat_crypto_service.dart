import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto_hash;
import 'package:cryptography/cryptography.dart';

/// Cryptographic service providing sound AES-256-GCM authenticated encryption
/// for SafeTalk peer sessions.
///
/// Encryption keys are per-session symmetric keys shared strictly between the
/// seeker and listener over authenticated channels (A2.5 - D-08).
class ChatCryptoService {
  static final ChatCryptoService _instance = ChatCryptoService._internal();
  factory ChatCryptoService() => _instance;
  ChatCryptoService._internal();

  final AesGcm _aesGcm = AesGcm.with256bits();

  /// Derives a 256-bit SecretKey deterministically from the session's shared key material.
  SecretKey _deriveSecretKey(String sessionKey) {
    final keyBytes = crypto_hash.sha256.convert(utf8.encode(sessionKey)).bytes;
    return SecretKey(keyBytes);
  }

  /// Generates a cryptographically secure random nonce.
  List<int> _generateRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  /// Encrypts plaintext using AES-256-GCM with a fresh 12-byte nonce.
  ///
  /// Returns a JSON-encoded string containing version, ciphertext, nonce, and MAC.
  Future<String> encryptMessage(String plaintext, String sessionKey) async {
    if (sessionKey.isEmpty) {
      throw ArgumentError('sessionKey must not be empty');
    }

    final secretKey = _deriveSecretKey(sessionKey);
    final cleartextBytes = utf8.encode(plaintext);
    final nonce = _generateRandomBytes(12);

    final secretBox = await _aesGcm.encrypt(
      cleartextBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    return jsonEncode({
      'v': 1,
      'c': base64Encode(secretBox.cipherText),
      'n': base64Encode(secretBox.nonce),
      'm': base64Encode(secretBox.mac.bytes),
    });
  }

  /// Decrypts a payload using AES-256-GCM with the session key.
  ///
  /// If the payload is unencrypted legacy text, it returns the text as-is.
  /// If decryption fails (tampered payload or incorrect key), returns fallback message.
  Future<String> decryptMessage(
    String payload,
    String sessionKey, {
    String failureFallback = '[Unable to decrypt message]',
  }) async {
    if (payload.trim().isEmpty) return '';
    if (sessionKey.isEmpty) return failureFallback;

    // Fast check for encrypted payload structure
    if (!payload.trim().startsWith('{')) {
      return payload; // Legacy / unencrypted plaintext
    }

    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      if (!data.containsKey('c') || !data.containsKey('n') || !data.containsKey('m')) {
        return payload; // JSON, but not our encrypted schema
      }

      final ciphertext = base64Decode(data['c'] as String);
      final nonce = base64Decode(data['n'] as String);
      final mac = base64Decode(data['m'] as String);

      final secretKey = _deriveSecretKey(sessionKey);
      final secretBox = SecretBox(
        ciphertext,
        nonce: nonce,
        mac: Mac(mac),
      );

      final cleartextBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      return utf8.decode(cleartextBytes);
    } catch (_) {
      return failureFallback;
    }
  }

  /// Generates a new cryptographically secure random session key string.
  static String generateSessionKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
