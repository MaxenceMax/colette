/// Raison d'une [ValidationFailure], traduite par la présentation.
enum ValidationReason {
  emptyEvent,
  endBeforeStart,
  startInFuture,
  bottleOutOfRange,
  invalidWeight,
  emptyName,
  unknownHouseholdCode,
  notificationsDenied,
  invalidDiaperCount,
}

/// Erreur remontée par les repositories et les use cases via `Either`.
sealed class Failure {
  const Failure();
}

/// Réseau indisponible ou appel Firestore échoué pour cause de connectivité.
final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// Ressource introuvable : code foyer inconnu, document supprimé.
final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

/// Donnée saisie invalide.
final class ValidationFailure extends Failure {
  const ValidationFailure(this.reason);

  final ValidationReason reason;
}

/// Erreur inattendue, conservée avec sa pile pour le log.
final class UnknownFailure extends Failure {
  const UnknownFailure(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;
}

/// Raison d'une [DocumentsFailure].
enum DocumentsReason { noFolder, accessDenied, cancelled, io }

/// Erreur du pont natif documents (dossier iCloud).
final class DocumentsFailure extends Failure {
  const DocumentsFailure(this.reason);

  final DocumentsReason reason;

  @override
  bool operator ==(Object other) =>
      other is DocumentsFailure && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}
