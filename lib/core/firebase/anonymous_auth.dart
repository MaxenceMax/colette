import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';

/// Ouvre une session anonyme si aucune n'existe, sans bloquer le démarrage
/// plus de [timeout] : hors ligne, la tentative continue en arrière-plan et
/// la prochaine ouverture réessaiera. Les échecs sont journalisés, jamais propagés.
Future<void> ensureAnonymousSession(
  FirebaseAuth auth, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  if (auth.currentUser != null) return;
  try {
    await auth.signInAnonymously().timeout(timeout);
  } on TimeoutException {
    developer.log(
      'Anonymous sign-in still pending after timeout',
      name: 'colette',
    );
  } on FirebaseAuthException catch (e, stackTrace) {
    developer.log(
      'Anonymous sign-in failed',
      error: e,
      stackTrace: stackTrace,
      name: 'colette',
    );
  } catch (e, stackTrace) {
    developer.log(
      'Anonymous sign-in failed unexpectedly',
      error: e,
      stackTrace: stackTrace,
      name: 'colette',
    );
  }
}
