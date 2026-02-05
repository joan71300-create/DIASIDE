// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// REMPLACEZ LES VALEURS CI-DESSOUS PAR VOS CLÉS RÉELLES
/// Disponibles dans : Console Firebase > Paramètres du projet > Vos applications
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDEKMhqeVtgt4fHV-WDjjVzMYqmiXvdqpc',
    appId: 'diaside',
    messagingSenderId: '1067747995927',
    projectId: 'diaside',
    authDomain: 'diaside.firebaseapp.com',
    storageBucket: 'diaside.firebasestorage.app',
    measurementId: '13384268031',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDEKMhqeVtgt4fHV-WDjjVzMYqmiXvdqpc',
    appId: 'diaside',
    messagingSenderId: '1067747995927',
    projectId: 'diaside',
    storageBucket: 'diaside.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDEKMhqeVtgt4fHV-WDjjVzMYqmiXvdqpc',
    appId: 'diaside',
    messagingSenderId: '1067747995927',
    projectId: 'diaside',
    storageBucket: 'diaside.firebasestorage.app',
    iosClientId: 'REMPLACER_PAR_IOS_CLIENT_ID',
    iosBundleId: 'com.example.diasideMobile',
  );
}
