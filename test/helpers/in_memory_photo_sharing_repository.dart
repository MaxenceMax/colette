import 'package:colette/core/result/failure.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/repositories/photo_sharing_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Stockage en mémoire ; [failSaves] fait échouer toutes les écritures,
/// [failLoads] la lecture des listes.
class InMemoryPhotoSharingRepository implements PhotoSharingRepository {
  InMemoryPhotoSharingRepository({
    this.lists = const [],
    this.lastSentAt,
    this.reminderEnabled = true,
  });

  List<BroadcastList> lists;
  DateTime? lastSentAt;
  bool reminderEnabled;
  bool failSaves = false;
  bool failLoads = false;

  Future<Either<Failure, void>> _write(void Function() apply) async {
    if (failSaves) return left(const UnknownFailure('écriture refusée'));
    apply();
    return right(null);
  }

  @override
  Future<Either<Failure, List<BroadcastList>>> loadLists() async =>
      failLoads ? left(const UnknownFailure('lecture refusée')) : right(lists);

  @override
  Future<Either<Failure, void>> saveLists(List<BroadcastList> lists) =>
      _write(() => this.lists = lists);

  @override
  Future<Either<Failure, DateTime?>> loadLastSentAt() async =>
      right(lastSentAt);

  @override
  Future<Either<Failure, void>> saveLastSentAt(DateTime sentAt) =>
      _write(() => lastSentAt = sentAt);

  @override
  Future<Either<Failure, bool>> loadReminderEnabled() async =>
      right(reminderEnabled);

  @override
  Future<Either<Failure, void>> saveReminderEnabled(bool enabled) =>
      _write(() => reminderEnabled = enabled);
}
