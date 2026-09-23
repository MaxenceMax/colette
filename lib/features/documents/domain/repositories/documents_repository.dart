import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:fpdart/fpdart.dart';

/// Accès au dossier iCloud choisi. Tous les chemins sont relatifs à la racine
/// (`''` pour la racine, séparateur `/`, jamais de `/` initial).
abstract interface class DocumentsRepository {
  /// Dossier racine courant, `null` si aucun n'a été choisi.
  Future<Either<Failure, DocumentRoot?>> rootFolder();

  /// Ouvre le sélecteur iOS ; `DocumentsReason.cancelled` si l'utilisateur annule.
  Future<Either<Failure, DocumentRoot>> pickRootFolder();

  /// Oublie le dossier : Colette ne l'affiche plus, rien n'est supprimé.
  Future<Either<Failure, void>> forgetRootFolder();

  /// Contenu brut (non trié) d'un dossier.
  Future<Either<Failure, List<DocumentEntry>>> list(String path);

  /// Contenu d'un dossier en direct : une liste complète (non triée) à chaque
  /// changement iCloud. Un `Left` est suivi de la fin du flux.
  Stream<Either<Failure, List<DocumentEntry>>> watch(String path);

  /// Lance le téléchargement iCloud du fichier et rend la main aussitôt.
  Future<Either<Failure, void>> download(String path);

  /// Supprime un fichier (jamais un dossier) ; iCloud le garde trente jours
  /// dans « Récemment supprimés ».
  Future<Either<Failure, void>> delete(String path);

  /// Ouvre l'app Fichiers sur ce dossier.
  Future<Either<Failure, void>> openInFiles(String path);

  /// Télécharge si besoin puis affiche l'aperçu ; revient à la fermeture.
  Future<Either<Failure, void>> preview(String path);

  /// Scanne avec l'appareil photo et écrit un PDF ; renvoie le nom final.
  Future<Either<Failure, String>> scan({
    required String folderPath,
    required String fileName,
  });

  /// Copie un fichier choisi par l'utilisateur ; renvoie le nom final.
  Future<Either<Failure, String>> importFile({required String folderPath});
}
