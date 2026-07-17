// lib/firebase_options.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  ACTION REQUIRED — This is a placeholder file.                      ║
// ║                                                                      ║
// ║  Replace this file by running:                                       ║
// ║    dart pub global activate flutterfire_cli                          ║
// ║    flutterfire configure                                             ║
// ║                                                                      ║
// ║  That command will auto-generate the real firebase_options.dart      ║
// ║  with your project's API keys and app IDs.                          ║
// ╚══════════════════════════════════════════════════════════════════════╝

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform. '
          'Run `flutterfire configure` to generate your firebase_options.dart.',
        );
    }
  }

  // ─── REPLACE ALL VALUES BELOW WITH YOUR FIREBASE PROJECT CONFIG ───────────
  // Run `flutterfire configure` to auto-populate these fields.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_ANDROID_API_KEY',
    appId: 'REPLACE_WITH_YOUR_ANDROID_APP_ID',
    messagingSenderId: 'REPLACE_WITH_YOUR_SENDER_ID',
    projectId: 'REPLACE_WITH_YOUR_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_IOS_API_KEY',
    appId: 'REPLACE_WITH_YOUR_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_YOUR_SENDER_ID',
    projectId: 'REPLACE_WITH_YOUR_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_YOUR_STORAGE_BUCKET',
    iosClientId: 'REPLACE_WITH_YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.driver.driver',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDslUwdBp0C57c84qvLOJe9_QdPo5sgx6E',
    appId: '1:829164680847:web:c8a28722b88f88eda8a2fa',
    messagingSenderId: '829164680847',
    projectId: 'last-mile-81251',
    authDomain: 'last-mile-81251.firebaseapp.com',
    storageBucket: 'last-mile-81251.firebasestorage.app',
  );
}
