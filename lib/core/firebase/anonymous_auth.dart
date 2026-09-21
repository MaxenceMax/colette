import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';

/// Ouvre une session anonyme si aucune n'existe. Silencieux en cas d'échec
/// réseau : la prochaine ouverture réessaiera.
Future<void> ensureAnonymousSession(FirebaseAuth auth) async {
  if (auth.currentUser != null) return;
  try {
    await auth.signInAnonymously();
  } on FirebaseAuthException catch (e, stackTrace) {
    developer.log(
      'Anonymous sign-in failed',
      error: e,
      stackTrace: stackTrace,
      name: 'colette',
    );
  }
}
