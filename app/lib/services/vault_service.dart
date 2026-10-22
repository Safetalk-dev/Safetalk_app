import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';

class CryptographicException implements Exception {
  final String message;
  CryptographicException(this.message);
  @override
  String toString() => 'CryptographicException: $message';
}

class VaultService {
  static final VaultService _instance = VaultService._internal();
  factory VaultService() => _instance;
  VaultService._internal();

  /// Directory override for testing or custom paths.
  static Directory? baseDirectoryOverride;
  static Directory? _cachedDirectory;

  /// Asynchronously resolve application directory on mobile devices (A2.7 - D-09).
  static Future<void> initializeDirectory() async {
    if (baseDirectoryOverride != null) {
      _cachedDirectory = baseDirectoryOverride;
      return;
    }
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      _cachedDirectory = Directory('data');
    } else {
      _cachedDirectory = await getApplicationDocumentsDirectory();
    }
  }

  Directory get _dataDir {
    if (baseDirectoryOverride != null) return baseDirectoryOverride!;
    if (_cachedDirectory != null) return _cachedDirectory!;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return Directory('data');
    }
    return Directory('data');
  }

  File get _metadataFile => File('${_dataDir.path}/vault_metadata.json');
  File get _notesFile => File('${_dataDir.path}/vault_notes.enc');

  final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 50000,
    bits: 256,
  );

  final _aesGcm = AesGcm.with256bits();

  // Helper to ensure data directory exists
  void _ensureDataDirExists() {
    final dir = _dataDir;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  /// Checks if the local vault has been initialized with a PIN.
  bool isVaultInitialized() {
    _ensureDataDirExists();
    return _metadataFile.existsSync();
  }

  /// Generates a random 256-bit salt (32 bytes)
  List<int> _generateRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  /// Initializes the vault by creating a salt and deriving the initial key.
  Future<void> initializeVault(String pin) async {
    _ensureDataDirExists();
    
    // 1. Generate unique random 256-bit salt
    final salt = _generateRandomBytes(32);
    
    // 2. Save metadata (salt) in cleartext
    await _metadataFile.writeAsString(jsonEncode({
      'salt_base64': base64Encode(salt),
    }));

    // 3. Encrypt an empty notes map initially
    await saveNotes(pin, {});
  }

  /// Derives 256-bit AES-GCM Key using PBKDF2 HMAC-SHA256 with 50,000 iterations
  Future<SecretKey> _deriveKey(String pin, List<int> salt) async {
    final pinBytes = utf8.encode(pin);
    final secretKey = SecretKey(pinBytes);
    
    final derivedKeyBytes = await _pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );
    
    return derivedKeyBytes;
  }

  /// Decrypts all notes using the provided PIN
  Future<Map<String, String>> unlockVault(String pin) async {
    if (!isVaultInitialized()) {
      throw CryptographicException('Vault is not initialized.');
    }

    try {
      // 1. Read salt
      final metadata = jsonDecode(await _metadataFile.readAsString());
      final salt = base64Decode(metadata['salt_base64'] as String);

      // 2. Read encrypted notes payload
      if (!_notesFile.existsSync()) {
        return {};
      }
      
      final encryptedData = jsonDecode(await _notesFile.readAsString());
      final ciphertext = base64Decode(encryptedData['ciphertext'] as String);
      final nonce = base64Decode(encryptedData['nonce'] as String);
      final mac = base64Decode(encryptedData['mac'] as String);

      // 3. Derive key in memory
      final secretKey = await _deriveKey(pin, salt);

      // 4. Decrypt via AES-GCM (verifying MAC tag dynamically)
      final secretBox = SecretBox(
        ciphertext,
        nonce: nonce,
        mac: Mac(mac),
      );

      final cleartextBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      final cleartext = utf8.decode(cleartextBytes);
      final Map<String, dynamic> decoded = jsonDecode(cleartext);
      
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      // wrong PIN naturally fails GCM auth tag check
      throw CryptographicException('Incorrect PIN or corrupted data.');
    }
  }

  /// Encrypts and saves notes under the user PIN
  Future<void> saveNotes(String pin, Map<String, String> notes) async {
    _ensureDataDirExists();
    
    // 1. Read salt
    if (!_metadataFile.existsSync()) {
      throw CryptographicException('Vault not initialized. Cannot save.');
    }
    
    final metadata = jsonDecode(await _metadataFile.readAsString());
    final salt = base64Decode(metadata['salt_base64'] as String);

    // 2. Derive key in memory
    final secretKey = await _deriveKey(pin, salt);

    // 3. Encrypt via AES-GCM
    final cleartext = jsonEncode(notes);
    final cleartextBytes = utf8.encode(cleartext);
    final nonce = _generateRandomBytes(12); // 96-bit IV is standard for GCM

    final secretBox = await _aesGcm.encrypt(
      cleartextBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    // 4. Write base64 encrypted payload (ciphertext, nonce, mac authentication tag)
    await _notesFile.writeAsString(jsonEncode({
      'ciphertext': base64Encode(secretBox.cipherText),
      'nonce': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes),
    }));
  }

  /// Wipes notes and metadata securely
  Future<void> wipeAndResetVault() async {
    _ensureDataDirExists();
    
    if (_metadataFile.existsSync()) {
      _metadataFile.deleteSync();
    }
    
    if (_notesFile.existsSync()) {
      _notesFile.deleteSync();
    }
  }

  /// Transition keys: decrypts existing notes and re-encrypts under new PIN
  Future<void> changePin(String oldPin, String newPin) async {
    final notes = await unlockVault(oldPin);
    await initializeVault(newPin); // Generates a fresh salt
    await saveNotes(newPin, notes); // Encrypts notes under new key
  }

  /// Encrypts a generic string using the user's PIN
  Future<String> encryptString(String pin, String plaintext) async {
    _ensureDataDirExists();
    
    if (!_metadataFile.existsSync()) {
      throw CryptographicException('Vault not initialized.');
    }
    
    final metadata = jsonDecode(await _metadataFile.readAsString());
    final salt = base64Decode(metadata['salt_base64'] as String);
    final secretKey = await _deriveKey(pin, salt);

    final cleartextBytes = utf8.encode(plaintext);
    final nonce = _generateRandomBytes(12);

    final secretBox = await _aesGcm.encrypt(
      cleartextBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    return jsonEncode({
      'ciphertext': base64Encode(secretBox.cipherText),
      'nonce': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes),
    });
  }

  /// Decrypts a generic string using the user's PIN
  Future<String> decryptString(String pin, String encryptedJson) async {
    if (!isVaultInitialized()) {
      throw CryptographicException('Vault is not initialized.');
    }

    try {
      final metadata = jsonDecode(await _metadataFile.readAsString());
      final salt = base64Decode(metadata['salt_base64'] as String);

      final encryptedData = jsonDecode(encryptedJson);
      final ciphertext = base64Decode(encryptedData['ciphertext'] as String);
      final nonce = base64Decode(encryptedData['nonce'] as String);
      final mac = base64Decode(encryptedData['mac'] as String);

      final secretKey = await _deriveKey(pin, salt);

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
    } catch (e) {
      throw CryptographicException('Incorrect PIN or corrupted data.');
    }
  }
}
