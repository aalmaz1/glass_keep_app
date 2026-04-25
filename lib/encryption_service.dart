import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static const _storage = FlutterSecureStorage();
  static const _keyAlias = 'encryption_key';
  static const _prefix = 'enc:';
  
  encrypt_lib.Key? _key;

  Future<void> init() async {
    String? base64Key = await _storage.read(key: _keyAlias);
    if (base64Key == null) {
      final newKey = encrypt_lib.Key.fromSecureRandom(32);
      await _storage.write(key: _keyAlias, value: newKey.base64);
      _key = newKey;
    } else {
      _key = encrypt_lib.Key.fromBase64(base64Key);
    }
  }

  String encryptText(String text) {
    final key = _key;
    if (key == null || text.isEmpty) return text;
    try {
      final iv = encrypt_lib.IV.fromSecureRandom(16);
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key, mode: encrypt_lib.AESMode.gcm));
      final encrypted = encrypter.encrypt(text, iv: iv);
      return '$_prefix${iv.base64}:${encrypted.base64}';
    } catch (e) {
      return text;
    }
  }

  String decryptText(String encryptedWithIv) {
    final key = _key;
    if (key == null || encryptedWithIv.isEmpty) return encryptedWithIv;
    if (!encryptedWithIv.startsWith(_prefix)) return encryptedWithIv;

    try {
      final data = encryptedWithIv.substring(_prefix.length);
      final parts = data.split(':');
      if (parts.length != 2) return encryptedWithIv;

      final iv = encrypt_lib.IV.fromBase64(parts[0]);
      final encryptedBase64 = parts[1];
      
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key, mode: encrypt_lib.AESMode.gcm));
      final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);
      return decrypted;
    } catch (e) {
      // If decryption fails, it might be because the text was not encrypted or key changed
      return encryptedWithIv;
    }
  }
}
