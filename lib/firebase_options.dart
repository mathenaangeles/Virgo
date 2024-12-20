// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA7AdzM5V9pGv7G9IZbYfzIHVBVsZGpgtw',
    appId: '1:579545767935:web:c6e63a2c94da1152e191ca',
    messagingSenderId: '579545767935',
    projectId: 'virgo-441112',
    authDomain: 'virgo-441112.firebaseapp.com',
    storageBucket: 'virgo-441112.firebasestorage.app',
    measurementId: 'G-75J9N78FHL',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD6gKUtSjkLtC-6TL8qZGI0Z0D2nDUQJyo',
    appId: '1:579545767935:android:4307cfa15893c54ee191ca',
    messagingSenderId: '579545767935',
    projectId: 'virgo-441112',
    storageBucket: 'virgo-441112.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDV8Nch5Qd8cV0_eNsEkWnw78_pWpPRYr0',
    appId: '1:579545767935:ios:b5cb69db59533534e191ca',
    messagingSenderId: '579545767935',
    projectId: 'virgo-441112',
    storageBucket: 'virgo-441112.firebasestorage.app',
    iosBundleId: 'com.example.virgo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDV8Nch5Qd8cV0_eNsEkWnw78_pWpPRYr0',
    appId: '1:579545767935:ios:b5cb69db59533534e191ca',
    messagingSenderId: '579545767935',
    projectId: 'virgo-441112',
    storageBucket: 'virgo-441112.firebasestorage.app',
    iosBundleId: 'com.example.virgo',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA7AdzM5V9pGv7G9IZbYfzIHVBVsZGpgtw',
    appId: '1:579545767935:web:1e2cb833e9663974e191ca',
    messagingSenderId: '579545767935',
    projectId: 'virgo-441112',
    authDomain: 'virgo-441112.firebaseapp.com',
    storageBucket: 'virgo-441112.firebasestorage.app',
    measurementId: 'G-KYH8N16SKQ',
  );
}
