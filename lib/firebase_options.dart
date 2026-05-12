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
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform - '
          'you can use flutterfire configure to generate this file.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDB1p1i91_RYYcAfprtki85ZMeEBy1kR1o',
    appId: '1:508575398900:web:f28c31f9d67471163f57a1',
    messagingSenderId: '508575398900',
    projectId: 'bivfarm',
    authDomain: 'bivfarm.firebaseapp.com',
    storageBucket: 'bivfarm.firebasestorage.app',
    measurementId: 'G-QSZJP5YDDE',
  );
}
