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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBsrhKx5xHIi167LjVaMJ_HK3W-bBAdpyw',
    appId: '1:585955210188:web:5f741583ef4e89ed192369',
    messagingSenderId: '585955210188',
    projectId: 'glasskeep-2a8e5',
    authDomain: 'glasskeep-2a8e5.firebaseapp.com',
    storageBucket: 'glasskeep-2a8e5.firebasestorage.app',
    measurementId: 'G-GZE669316H',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBsrhKx5xHIi167LjVaMJ_HK3W-bBAdpyw',
    appId: '1:585955210188:web:5f741583ef4e89ed192369',
    messagingSenderId: '585955210188',
    projectId: 'glasskeep-2a8e5',
    storageBucket: 'glasskeep-2a8e5.firebasestorage.app',
    authDomain: 'glasskeep-2a8e5.firebaseapp.com',
    measurementId: 'G-GZE669316H',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBsrhKx5xHIi167LjVaMJ_HK3W-bBAdpyw',
    appId: '1:585955210188:web:5f741583ef4e89ed192369',
    messagingSenderId: '585955210188',
    projectId: 'glasskeep-2a8e5',
    storageBucket: 'glasskeep-2a8e5.firebasestorage.app',
    authDomain: 'glasskeep-2a8e5.firebaseapp.com',
    iosBundleId: 'com.glasskeep.app',
    measurementId: 'G-GZE669316H',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBsrhKx5xHIi167LjVaMJ_HK3W-bBAdpyw',
    appId: '1:585955210188:web:5f741583ef4e89ed192369',
    messagingSenderId: '585955210188',
    projectId: 'glasskeep-2a8e5',
    storageBucket: 'glasskeep-2a8e5.firebasestorage.app',
    authDomain: 'glasskeep-2a8e5.firebaseapp.com',
    iosBundleId: 'com.glasskeep.app',
    measurementId: 'G-GZE669316H',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBsrhKx5xHIi167LjVaMJ_HK3W-bBAdpyw',
    appId: '1:585955210188:web:5f741583ef4e89ed192369',
    messagingSenderId: '585955210188',
    projectId: 'glasskeep-2a8e5',
    authDomain: 'glasskeep-2a8e5.firebaseapp.com',
    storageBucket: 'glasskeep-2a8e5.firebasestorage.app',
    measurementId: 'G-GZE669316H',
  );
}
