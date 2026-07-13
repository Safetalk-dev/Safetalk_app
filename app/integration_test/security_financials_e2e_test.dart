import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app/firebase_options.dart';
import 'package:app/services/vault_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4: Security and Timeout E2E Tests', () {
    setUpAll(() async {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
    });

    testWidgets('Messages are stored encrypted and decrypted successfully', (WidgetTester tester) async {
      final vault = VaultService();
      await vault.wipeAndResetVault();
      
      // Initialize Vault for test
      const pin = '1234';
      await vault.initializeVault(pin);

      final plaintext = 'Hello, this is a secret message!';
      final encryptedJson = await vault.encryptString(pin, plaintext);
      final encryptedMap = jsonDecode(encryptedJson) as Map<String, dynamic>;

      expect(encryptedMap['ciphertext'], isNotNull);
      expect(encryptedMap['nonce'], isNotNull);
      expect(encryptedMap['mac'], isNotNull);
      expect(encryptedMap['ciphertext'], isNot(plaintext)); // Ensure it's actually encrypted

      // Simulate writing to Firestore
      const testSessionId = 'test_session_123';
      final messageRef = FirebaseFirestore.instance
          .collection('sessions')
          .doc(testSessionId)
          .collection('messages')
          .doc('msg1');

      await messageRef.set({
        'encryptedData': encryptedMap,
        'senderId': 'user1',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Simulate reading from Firestore
      final snapshot = await messageRef.get();
      final data = snapshot.data()!;
      final retrievedEncryptedData = data['encryptedData'] as Map<String, dynamic>;
      final retrievedEncryptedJson = jsonEncode(retrievedEncryptedData);

      // Decrypt
      final decryptedText = await vault.decryptString(pin, retrievedEncryptedJson);

      expect(decryptedText, plaintext);

      // Clean up
      await messageRef.delete();
      await vault.wipeAndResetVault();
    });
  });
}
