import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opções padrão do Firebase por plataforma (projeto `app-iadet`).
///
/// Os valores de Android são os mesmos de `android/app/google-services.json`;
/// os de web, do Web App em Firebase Console > Project settings > Your apps
/// (também duplicados em `web/firebase-messaging-sw.js` — manter em sincronia).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não configurado para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCeHQKj_SjVwQr92S_GVXuskcTVPMZ2YBA',
    appId: '1:46968246148:android:968641747e8755926397d1',
    messagingSenderId: '46968246148',
    projectId: 'app-iadet',
    storageBucket: 'app-iadet.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDKfUM3YPPWlp4T51AV1YYAoGZf1uTc3RQ',
    appId: '1:46968246148:web:4b39e0f910ff3d6c6397d1',
    messagingSenderId: '46968246148',
    projectId: 'app-iadet',
    authDomain: 'app-iadet.firebaseapp.com',
    storageBucket: 'app-iadet.firebasestorage.app',
    measurementId: 'G-KS09F7034V',
  );
}
