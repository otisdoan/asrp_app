import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// Firebase configuration — file này nằm trong .gitignore.
/// Team member mới: copy firebase_options.dart.example → firebase_options.dart rồi điền keys.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCkUgUlIQVGmhzQr9tpCFaOb-Fu0iVWKZQ',
    appId: '1:344850115118:web:ae3dea807bcff6983ccdbf',
    messagingSenderId: '344850115118',
    projectId: 'arsp-b43a9',
    storageBucket: 'arsp-b43a9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCkUgUlIQVGmhzQr9tpCFaOb-Fu0iVWKZQ',
    appId: '1:344850115118:web:ae3dea807bcff6983ccdbf',
    messagingSenderId: '344850115118',
    projectId: 'arsp-b43a9',
    storageBucket: 'arsp-b43a9.firebasestorage.app',
    iosBundleId: 'com.example.feAsrpApp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCkUgUlIQVGmhzQr9tpCFaOb-Fu0iVWKZQ',
    appId: '1:344850115118:web:ae3dea807bcff6983ccdbf',
    messagingSenderId: '344850115118',
    projectId: 'arsp-b43a9',
    storageBucket: 'arsp-b43a9.firebasestorage.app',
    authDomain: 'arsp-b43a9.firebaseapp.com',
    measurementId: 'G-6SN397H5G1',
  );
}
