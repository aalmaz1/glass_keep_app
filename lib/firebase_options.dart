import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform, debugPrint;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    _logKeys();
    
    // Check for empty or placeholder values
    if (_isInvalid(_apiKey) || _isInvalid(_appId) || _isInvalid(_projectId) || _isInvalid(_messagingSenderId)) {
      const errorMsg = 'Firebase configuration is incomplete or contains placeholders! '
          'FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_PROJECT_ID and FIREBASE_MESSAGING_SENDER_ID are required and must be valid.';
      debugPrint('\n\x1B[31m[ERROR] $errorMsg\x1B[0m\n');
      throw StateError(errorMsg);
    }
    
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for linux - please run flutterfire configure.');
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static void _logKeys() {
    debugPrint('[SYSTEM-REBORN] FIREBASE_API_KEY: ${_apiKey.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_APP_ID: ${_appId.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_API_KEY_ANDROID: ${_apiKeyAndroidRaw.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_APP_ID_ANDROID: ${_appIdAndroidRaw.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_API_KEY_IOS: ${_apiKeyIosRaw.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_APP_ID_IOS: ${_appIdIosRaw.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_API_KEY_WEB: ${_apiKeyWebRaw.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_APP_ID_WEB: ${_appIdWebRaw.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_MESSAGING_SENDER_ID: ${_messagingSenderId.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_PROJECT_ID: ${_projectId.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_AUTH_DOMAIN: ${_authDomain.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_STORAGE_BUCKET: ${_storageBucket.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_MEASUREMENT_ID: ${_measurementId.isNotEmpty ? "FOUND" : "EMPTY"}');
  }

  static bool _isInvalid(String value) {
    if (value.isEmpty) return true;
    final lower = value.toLowerCase();
    return lower.contains('your_') || lower.contains('_here');
  }

  // Generic fallback secrets
  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _appId = String.fromEnvironment('FIREBASE_APP_ID');

  // Android specific
  static const String _apiKeyAndroidRaw = String.fromEnvironment('FIREBASE_API_KEY_ANDROID');
  static const String _apiKeyAndroid = _apiKeyAndroidRaw != '' ? _apiKeyAndroidRaw : _apiKey;
  static const String _appIdAndroidRaw = String.fromEnvironment('FIREBASE_APP_ID_ANDROID');
  static const String _appIdAndroid = _appIdAndroidRaw != '' ? _appIdAndroidRaw : _appId;

  // iOS specific
  static const String _apiKeyIosRaw = String.fromEnvironment('FIREBASE_API_KEY_IOS');
  static const String _apiKeyIos = _apiKeyIosRaw != '' ? _apiKeyIosRaw : _apiKey;
  static const String _appIdIosRaw = String.fromEnvironment('FIREBASE_APP_ID_IOS');
  static const String _appIdIos = _appIdIosRaw != '' ? _appIdIosRaw : _appId;

  // Web specific
  static const String _apiKeyWebRaw = String.fromEnvironment('FIREBASE_API_KEY_WEB');
  static const String _apiKeyWeb = _apiKeyWebRaw != '' ? _apiKeyWebRaw : _apiKey;
  static const String _appIdWebRaw = String.fromEnvironment('FIREBASE_APP_ID_WEB');
  static const String _appIdWeb = _appIdWebRaw != '' ? _appIdWebRaw : _appId;

  static const String _messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String _measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');
  static const String _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: 'com.glasskeep.app');

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKeyWeb,
    appId: _appIdWeb,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: _authDomain != '' ? _authDomain : null,
    storageBucket: _storageBucket != '' ? _storageBucket : null,
    measurementId: _measurementId != '' ? _measurementId : null,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKeyAndroid,
    appId: _appIdAndroid,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket != '' ? _storageBucket : null,
    authDomain: _authDomain != '' ? _authDomain : null,
    measurementId: _measurementId != '' ? _measurementId : null,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKeyIos,
    appId: _appIdIos,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket != '' ? _storageBucket : null,
    authDomain: _authDomain != '' ? _authDomain : null,
    iosBundleId: _iosBundleId,
    measurementId: _measurementId != '' ? _measurementId : null,
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: _apiKeyIos,
    appId: _appIdIos,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket != '' ? _storageBucket : null,
    authDomain: _authDomain != '' ? _authDomain : null,
    iosBundleId: _iosBundleId,
    measurementId: _measurementId != '' ? _measurementId : null,
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: _authDomain != '' ? _authDomain : null,
    storageBucket: _storageBucket != '' ? _storageBucket : null,
    measurementId: _measurementId != '' ? _measurementId : null,
  );
}
