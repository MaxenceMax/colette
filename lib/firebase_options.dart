// Placeholder : remplacer ce fichier par la sortie de
// `flutterfire configure --platforms=ios`.
import 'package:firebase_core/firebase_core.dart';

/// Options Firebase de l'app. Les valeurs ci-dessous sont factices
/// et permettent seulement de compiler et de lancer les tests.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => ios;

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'colette-placeholder',
    storageBucket: 'colette-placeholder.appspot.com',
    iosBundleId: 'com.example.colette',
  );
}
