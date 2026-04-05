// ignore_for_file: avoid_print

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for different platforms
/// 
/// IMPORTANT: These values should be loaded from environment variables
/// in production. See .env.example for required keys.
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
      default:
        throw UnsupportedError(
          'Firebase is not configured for this platform: $defaultTargetPlatform',
        );
    }
  }

  /// Web Firebase configuration
  /// Generated using: flutterfire configure
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBsrhKx5xHIi167LjVaMJ_HK3W-bBAdpyw',
    appId: '1:585955210188:web:5f741583ef4e89ed192369',
    messagingSenderId: '585955210188',
    projectId: 'glasskeep-2a8e5',
    authDomain: 'glasskeep-2a8e5.firebaseapp.com',
    storageBucket: 'glasskeep-2a8e5.firebasestorage.app',
    measurementId: 'G-GZE669316H',
  );

  /// Android Firebase configuration
  /// Generated using: flutterfire configure
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDuSsHleJ-xKZc4X3CWjPzmqO-BD6kn2TE',
    appId: '1:585955210188:android:14371eb6a66b9e52192369',
    messagingSenderId: '585955210188',
    projectId: 'glasskeep-2a8e5',
    storageBucket: 'glasskeep-2a8e5.firebasestorage.app',
  );

  /// iOS Firebase configuration
  /// Generated using: flutterfire configure
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBxluZTqezRbs-9VxUsRyktE4tXs_UyPcU',
    appId: '1:585955210188:ios:bf916459532acd26192369',
    messagingSenderId: '585955210188',
    projectId: 'glasskeep-2a8e5',
    storageBucket: 'glasskeep-2a8e5.firebasestorage.app',
    iosBundleId: 'com.example.glassKeepApp',
  );

  /// macOS Firebase configuration
  /// Shares iOS bundle ID
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBxluZTqezRbs-9VxUsRyktE4tXs_UyPcU',
    appId: '1:585955210188:ios:bf916459532acd26192369',
    messagingSenderId: '585955210188',
    projectId: 'glasskeep-2a8e5',
    storageBucket: 'glasskeep-2a8e5.firebasestorage.app',
    iosBundleId: 'com.example.glassKeepApp',
  );

  /// Windows Firebase configuration
  /// Generated using: flutterfire configure
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBsrhKx5xHIi167LjVaMJ_HK3W-bBAdpyw',
    appId: '1:585955210188:web:f77d29579e51a9d3192369',
    messagingSenderId: '585955210188',
    projectId: 'glasskeep-2a8e5',
    authDomain: 'glasskeep-2a8e5.firebaseapp.com',
    storageBucket: 'glasskeep-2a8e5.firebasestorage.app',
    measurementId: 'G-T2KMZ5YJP5',
  );
}
