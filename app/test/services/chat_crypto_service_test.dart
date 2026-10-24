import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/chat_crypto_service.dart';

void main() {
  group('ChatCryptoService (A2.5 - D-08)', () {
    late ChatCryptoService cryptoService;

    setUp(() {
      cryptoService = ChatCryptoService();
    });

    test('generateSessionKey produces distinct 256-bit base64 keys', () {
      final key1 = ChatCryptoService.generateSessionKey();
      final key2 = ChatCryptoService.generateSessionKey();

      expect(key1, isNotEmpty);
      expect(key2, isNotEmpty);
      expect(key1, isNot(equals(key2)));
      // Base64Url decoded length should be 32 bytes (256 bits)
      expect(base64Url.decode(key1).length, 32);
    });

    test('encrypts and decrypts message correctly with session key', () async {
      final sessionKey = ChatCryptoService.generateSessionKey();
      const plaintext = 'Hello! I am feeling anxious today.';

      final encrypted = await cryptoService.encryptMessage(
        plaintext,
        sessionKey,
      );
      expect(encrypted, contains('"v":1'));
      expect(encrypted, contains('"c":'));
      expect(encrypted, contains('"n":'));
      expect(encrypted, contains('"m":'));

      final decrypted = await cryptoService.decryptMessage(
        encrypted,
        sessionKey,
      );
      expect(decrypted, equals(plaintext));
    });

    test(
      'produces different ciphertexts for identical plaintext (nondeterministic IV)',
      () async {
        final sessionKey = ChatCryptoService.generateSessionKey();
        const plaintext = 'Consistent message';

        final enc1 = await cryptoService.encryptMessage(plaintext, sessionKey);
        final enc2 = await cryptoService.encryptMessage(plaintext, sessionKey);

        expect(enc1, isNot(equals(enc2)));
        expect(await cryptoService.decryptMessage(enc1, sessionKey), plaintext);
        expect(await cryptoService.decryptMessage(enc2, sessionKey), plaintext);
      },
    );

    test(
      'returns fallback message when decrypted with an incorrect key',
      () async {
        final keyAlice = ChatCryptoService.generateSessionKey();
        final keyEve = ChatCryptoService.generateSessionKey();
        const plaintext = 'Top secret peer conversation';

        final encrypted = await cryptoService.encryptMessage(
          plaintext,
          keyAlice,
        );
        final decrypted = await cryptoService.decryptMessage(encrypted, keyEve);

        expect(decrypted, equals('[Unable to decrypt message]'));
      },
    );

    test(
      'returns fallback message when ciphertext or MAC is tampered with',
      () async {
        final sessionKey = ChatCryptoService.generateSessionKey();
        const plaintext = 'Tamper test';

        final encrypted = await cryptoService.encryptMessage(
          plaintext,
          sessionKey,
        );
        final Map<String, dynamic> data = jsonDecode(encrypted);

        // Corrupt the ciphertext bytes
        final rawCipher = base64Decode(data['c'] as String);
        rawCipher[0] = rawCipher[0] ^ 0xFF;
        data['c'] = base64Encode(rawCipher);

        final tamperedJson = jsonEncode(data);
        final decrypted = await cryptoService.decryptMessage(
          tamperedJson,
          sessionKey,
        );

        expect(decrypted, equals('[Unable to decrypt message]'));
      },
    );

    test('gracefully returns legacy/unencrypted plaintext unchanged', () async {
      final sessionKey = ChatCryptoService.generateSessionKey();
      const legacyPlaintext = 'Plain text before encryption was enabled';

      final result = await cryptoService.decryptMessage(
        legacyPlaintext,
        sessionKey,
      );
      expect(result, equals(legacyPlaintext));
    });

    test('handles empty message strings cleanly', () async {
      final sessionKey = ChatCryptoService.generateSessionKey();
      final result = await cryptoService.decryptMessage('', sessionKey);
      expect(result, isEmpty);
    });
  });
}
