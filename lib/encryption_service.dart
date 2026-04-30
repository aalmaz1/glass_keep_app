import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static const _secureStorage = FlutterSecureStorage();
  static const _keyAlias = 'encryption_key';
  static const _prefix = 'enc:';
  
  encrypt_lib.Key? _key;

  Future<void> init() async {
    debugPrint('[SYSTEM-REBORN] Initializing EncryptionService...');
    String? base64Key;
    
    if (kIsWeb) {
      // On web, use SharedPreferences (localStorage) instead of flutter_secure_storage
      final prefs = await SharedPreferences.getInstance();
      base64Key = prefs.getString(_keyAlias);
    } else {
      base64Key = await _secureStorage.read(key: _keyAlias);
    }
    
    if (base64Key == null) {
      final newKey = encrypt_lib.Key.fromSecureRandom(32);
      base64Key = newKey.base64;
      
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyAlias, base64Key);
      } else {
        await _secureStorage.write(key: _keyAlias, value: base64Key);
      }
      _key = newKey;
    } else {
      _key = encrypt_lib.Key.fromBase64(base64Key);
    }
    debugPrint('[SYSTEM-REBORN] EncryptionService initialized');
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
      // If decryption fails, return empty string instead of showing encrypted data
      debugPrint('[ENCRYPTION] Decryption failed: $e');
      return '';
    }
  }
}
