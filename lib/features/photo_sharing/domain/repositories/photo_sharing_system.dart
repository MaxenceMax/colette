import 'package:colette/core/result/failure.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:fpdart/fpdart.dart';

/// Écrans et services iOS du partage de photos. Une annulation par
/// l'utilisateur n'est pas une erreur : `null` ou liste vide.
abstract interface class PhotoSharingSystem {
  /// Sélecteur de contacts ; `null` si annulé.
  Future<Either<Failure, Recipient?>> pickContact();

  /// Appareil photo ; chemins des JPEG préparés (0 ou 1).
  Future<Either<Failure, List<String>>> takePhoto();

  /// Galerie, sélection multiple ; chemins des JPEG préparés (0 à 10).
  Future<Either<Failure, List<String>>> pickPhotos();

  /// Une feuille Messages par numéro, l'une après l'autre.
  Future<Either<Failure, SendReport>> sendMessages({
    required List<String> phones,
    required List<String> photoPaths,
    required String body,
  });

  /// Supprime les JPEG préparés ; échec seulement logué.
  Future<void> discardPhotos(List<String> photoPaths);

  /// Remplace les notifications du rappel photo par [dates] ; échec logué.
  Future<void> syncReminders({
    required List<DateTime> dates,
    required String title,
    required String body,
  });

  /// Route demandée par l'appui sur une notification, effacée à la lecture.
  Future<String?> takePendingRoute();

  /// Émis quand une route vient d'être mémorisée (app déjà lancée).
  Stream<void> get pendingRouteSignals;
}
