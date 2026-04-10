import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
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

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY_WEB', defaultValue: ''),
    appId: const String.fromEnvironment('FIREBASE_APP_ID_WEB', defaultValue: ''),
    messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: ''),
    projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
    authDomain: const String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: ''),
    storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: ''),
    measurementId: const String.fromEnvironment('FIREBASE_MEASUREMENT_ID', defaultValue: ''),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY_ANDROID', defaultValue: ''),
    appId: const String.fromEnvironment('FIREBASE_APP_ID_ANDROID', defaultValue: ''),
    messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: ''),
    projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
    storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: ''),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY_IOS', defaultValue: ''),
    appId: const String.fromEnvironment('FIREBASE_APP_ID_IOS', defaultValue: ''),
    messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: ''),
    projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
    storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: ''),
    iosBundleId: const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: ''),
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY_IOS', defaultValue: ''),
    appId: const String.fromEnvironment('FIREBASE_APP_ID_IOS', defaultValue: ''),
    messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: ''),
    projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
    storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: ''),
    iosBundleId: const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: ''),
  );

  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY_WINDOWS', defaultValue: ''),
    appId: const String.fromEnvironment('FIREBASE_APP_ID_WINDOWS', defaultValue: ''),
    messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: ''),
    projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
    authDomain: const String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: ''),
    storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: ''),
    measurementId: const String.fromEnvironment('FIREBASE_MEASUREMENT_ID', defaultValue: ''),
  );

}