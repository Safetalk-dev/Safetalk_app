import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/vault_service.dart';

void main() {
  group('VaultService Encryption/Decryption Tests', () {
    late VaultService vaultService;

    setUp(() async {
      vaultService = VaultService();
      // Ensure clean state
      await vaultService.wipeAndResetVault();
      
      // Initialize with a PIN
      await vaultService.initializeVault('1234');
    });

    tearDown(() async {
      // Clean up local files created during test
      await vaultService.wipeAndResetVault();
      
      // Delete data directory if it's empty
      final dir = Directory('data');
      if (dir.existsSync()) {
        try {
          dir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('encryptString and decryptString with correct PIN', () async {
      const plaintext = 'This is a super secret chat message.';
      const pin = '1234';

      final ciphertext = await vaultService.encryptString(pin, plaintext);
      
      expect(ciphertext, isNot(contains(plaintext)));
      
      final decrypted = await vaultService.decryptString(pin, ciphertext);
      
      expect(decrypted, equals(plaintext));
    });

    test('decryptString fails with incorrect PIN', () async {
      const plaintext = 'Another secret message';
      const pin = '1234';
      const wrongPin = '4321';

      final ciphertext = await vaultService.encryptString(pin, plaintext);
      
      expect(
        () => vaultService.decryptString(wrongPin, ciphertext),
        throwsA(isA<CryptographicException>()),
      );
    });

    test('Vault correctly detects initialization state', () async {
      expect(vaultService.isVaultInitialized(), isTrue);
      
      await vaultService.wipeAndResetVault();
      
      expect(vaultService.isVaultInitialized(), isFalse);
    });
  });
}
