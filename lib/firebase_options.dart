// File generated from Firebase Console configuration.
// Do NOT commit API keys to public repositories.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS. '
          'Register an iOS app in the Firebase Console and re-run flutterfire configure.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS. '
          'Register a macOS app in the Firebase Console and re-run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCXJQstAcTQJWQRT8mASOJe6PIR-lrczig',
    authDomain: 'splitwise-a64d2.firebaseapp.com',
    projectId: 'splitwise-a64d2',
    storageBucket: 'splitwise-a64d2.firebasestorage.app',
    messagingSenderId: '1094838385635',
    appId: '1:1094838385635:web:c1bda7d493f0b9e8c3fed6',
    measurementId: 'G-YZTB7W8L4Q',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDxGpmUd_v51iLEjO4AtBuu3DKTFaOikJg',
    appId: '1:1094838385635:android:3fe516c38f0a8086c3fed6',
    messagingSenderId: '1094838385635',
    projectId: 'splitwise-a64d2',
    storageBucket: 'splitwise-a64d2.firebasestorage.app',
  );
}
