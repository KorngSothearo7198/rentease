import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
          'Platform not supported',
        );
    }
  }


  static const FirebaseOptions android = FirebaseOptions(

  apiKey: 'AIzaSyBzqJIUf2C6dw8_JBbmxfYwYzjq3JyPas4',

  appId: '1:224673300178:android:b458992c2e480c0ec9b70b',

  messagingSenderId: '224673300178',

  projectId: 'rentease-211f2',

  storageBucket: 'rentease-211f2.firebasestorage.app',

);

  static const FirebaseOptions web = FirebaseOptions(

    apiKey: 'AIzaSyDiwCCnrKEE6Q4MXNnKHXDaCaIWiTX32TQ',

    appId: '1:224673300178:web:248546aaa68ea29dc9b70b',

    messagingSenderId: '224673300178',

    projectId: 'rentease-211f2',

    authDomain: 'rentease-211f2.firebaseapp.com',

    storageBucket: 'rentease-211f2.firebasestorage.app',

    measurementId: 'G-PQKGEQ9SJ3',

  );


  static const FirebaseOptions ios = FirebaseOptions(

    apiKey: 'AIzaSyDsRy0ycQOO_bgPal_9IEZzm11UgfVdiTM',

    appId: '1:224673300178:ios:0dccfcf6db9b0126c9b70b',

    messagingSenderId: '224673300178',

    projectId: 'rentease-211f2',

    storageBucket: 'rentease-211f2.firebasestorage.app',

  );

}