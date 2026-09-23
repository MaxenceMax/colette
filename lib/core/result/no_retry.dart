/// Politique de relance Riverpod « jamais » : la failure remonte en `AsyncError`
/// dès la première erreur, sans passer par `AsyncLoading(retrying: true)`.
///
/// À poser en `@Riverpod(retry: noRetry)` sur les providers qui écoutent
/// Firestore : `.snapshots()` gère déjà sa propre reconnexion, et une erreur
/// `permission-denied` ne se résout pas en relançant le listener.
Duration? noRetry(int retryCount, Object error) => null;
