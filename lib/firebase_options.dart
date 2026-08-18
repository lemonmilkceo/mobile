// Firebase options for Android `app.privatematching.baeandlee_app`
// and iOS `app.privatematching.baeandleeApp`.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web is not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAdGKxM3lq8gDwng38KFMRiLrrtokMWrzs',
    appId: '1:109126277161:android:05425be04a0c22ac12e438',
    messagingSenderId: '109126277161',
    projectId: 'private-matching',
    storageBucket: 'private-matching.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBGlMqIRGYnXz-75oLXzDywIdi2gbdbeo0',
    appId: '1:109126277161:ios:35ac774eaf57f21b12e438',
    messagingSenderId: '109126277161',
    projectId: 'private-matching',
    storageBucket: 'private-matching.firebasestorage.app',
    iosBundleId: 'app.privatematching.baeandleeApp',
  );
}
