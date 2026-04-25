import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform, debugPrint;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    _logKeys();
    if (_apiKey.isEmpty || _appId.isEmpty || _projectId.isEmpty) {
      final errorMsg = 'Firebase configuration is incomplete! FIREBASE_API_KEY, FIREBASE_APP_ID, and FIREBASE_PROJECT_ID are required.';
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
    debugPrint('[SYSTEM-REBORN] FIREBASE_MESSAGING_SENDER_ID: ${_messagingSenderId.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_PROJECT_ID: ${_projectId.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_AUTH_DOMAIN: ${_authDomain.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_STORAGE_BUCKET: ${_storageBucket.isNotEmpty ? "FOUND" : "EMPTY"}');
    debugPrint('[SYSTEM-REBORN] FIREBASE_MEASUREMENT_ID: ${_measurementId.isNotEmpty ? "FOUND" : "EMPTY"}');
  }

  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String _measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');
  static const String _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: 'com.glasskeep.app');

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: _authDomain,
    storageBucket: _storageBucket,
    measurementId: _measurementId,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    authDomain: _authDomain,
    measurementId: _measurementId,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    authDomain: _authDomain,
    iosBundleId: _iosBundleId,
    measurementId: _measurementId,
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    authDomain: _authDomain,
    iosBundleId: _iosBundleId,
    measurementId: _measurementId,
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: _authDomain,
    storageBucket: _storageBucket,
    measurementId: _measurementId,
  );
}
