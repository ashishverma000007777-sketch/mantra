// lib/firebase_options.dart
// AUTO-GENERATED — Replace with your actual Firebase config
// Run: flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unknown platform');
    }
  }

  // REPLACE WITH YOUR CONFIG FROM: Firebase Console > Project Settings > Your Apps
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: '1:YOUR_APP_ID:android:YOUR_HASH',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'mantra-app-prod',
    storageBucket: 'mantra-app-prod.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:YOUR_APP_ID:ios:YOUR_HASH',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'mantra-app-prod',
    storageBucket: 'mantra-app-prod.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'in.mantraapp.app',
  );
}
