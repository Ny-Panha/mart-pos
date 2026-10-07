// File generated for Mart POS App with Firebase
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDnUciY9Y_b6Mvyp_g3B-1a7PexO0vd5nM',
    appId: '1:1015671489262:web:fe46b0ab338ae0d683e9ff',
    messagingSenderId: '1015671489262',
    projectId: 'mart-pos-app',
    authDomain: 'mart-pos-app.firebaseapp.com',
    storageBucket: 'mart-pos-app.firebasestorage.app',
    measurementId: 'G-NE1CDPR6HM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgvCVGi9cstdfKTsrMGfPyWTTgspD9U_4',
    appId: '1:1015671489262:android:0b215e960034072a83e9ff',
    messagingSenderId: '1015671489262',
    projectId: 'mart-pos-app',
    storageBucket: 'mart-pos-app.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCKfUdUrAz2pNowkF0iDzSRFNO0espouXQ',
    appId: '1:1015671489262:ios:31f3ce24b3a0cdae83e9ff',
    messagingSenderId: '1015671489262',
    projectId: 'mart-pos-app',
    storageBucket: 'mart-pos-app.firebasestorage.app',
    iosBundleId: 'com.bbu.martpos.martPos',
  );
  static const FirebaseOptions macos = ios;
  static const FirebaseOptions windows = web;
}
