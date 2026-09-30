import 'package:colette/core/result/failure.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:fpdart/fpdart.dart';

/// Stockage local (propre à cet iPhone) du partage de photos.
abstract interface class PhotoSharingRepository {
  /// Liste vide si rien n'est enregistré.
  Future<Either<Failure, List<BroadcastList>>> loadLists();

  Future<Either<Failure, void>> saveLists(List<BroadcastList> lists);

  /// `null` si aucun envoi n'a réussi.
  Future<Either<Failure, DateTime?>> loadLastSentAt();

  Future<Either<Failure, void>> saveLastSentAt(DateTime sentAt);

  /// Vrai par défaut.
  Future<Either<Failure, bool>> loadReminderEnabled();

  Future<Either<Failure, void>> saveReminderEnabled(bool enabled);
}
