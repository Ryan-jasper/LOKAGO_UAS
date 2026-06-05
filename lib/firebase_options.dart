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
    apiKey: 'AIzaSyD3AFM4x8GvV2juej0f1JwRUj3ttp-1vyU',
    appId: '1:249245937428:web:0d7cf89d291807145b5c01',
    messagingSenderId: '249245937428',
    projectId: 'lokago-3646d',
    authDomain: 'lokago-3646d.firebaseapp.com',
    storageBucket: 'lokago-3646d.firebasestorage.app',
    measurementId: 'G-LNGHZQVGLY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDWwlLMkXwXsQ3v4Jp2JBc511FxKIvRYsw',
    appId: '1:249245937428:android:342e1c5f5877a25d5b5c01',
    messagingSenderId: '249245937428',
    projectId: 'lokago-3646d',
    storageBucket: 'lokago-3646d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDOhOckQC2p5rERuzaqv33CP-5gxtYTpKE',
    appId: '1:249245937428:ios:bfed4f4fbd2b61e85b5c01',
    messagingSenderId: '249245937428',
    projectId: 'lokago-3646d',
    storageBucket: 'lokago-3646d.firebasestorage.app',
    iosBundleId: 'com.example.application10',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDOhOckQC2p5rERuzaqv33CP-5gxtYTpKE',
    appId: '1:249245937428:ios:bfed4f4fbd2b61e85b5c01',
    messagingSenderId: '249245937428',
    projectId: 'lokago-3646d',
    storageBucket: 'lokago-3646d.firebasestorage.app',
    iosBundleId: 'com.example.application10',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD3AFM4x8GvV2juej0f1JwRUj3ttp-1vyU',
    appId: '1:249245937428:web:9a9a6113496421405b5c01',
    messagingSenderId: '249245937428',
    projectId: 'lokago-3646d',
    authDomain: 'lokago-3646d.firebaseapp.com',
    storageBucket: 'lokago-3646d.firebasestorage.app',
    measurementId: 'G-505WC81BQV',
  );
}
