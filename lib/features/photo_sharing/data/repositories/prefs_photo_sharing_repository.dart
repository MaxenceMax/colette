import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/photo_sharing/data/dtos/broadcast_list_dto.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/repositories/photo_sharing_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Partage de photos dans `shared_preferences`.
class PrefsPhotoSharingRepository implements PhotoSharingRepository {
  PrefsPhotoSharingRepository(this._prefs);

  static const listsKey = 'photo_sharing.lists';
  static const lastSentAtKey = 'photo_sharing.last_sent_at';
  static const reminderEnabledKey = 'photo_sharing.reminder_enabled';

  final SharedPreferences _prefs;

  @override
  Future<Either<Failure, List<BroadcastList>>> loadLists() => guard(() async {
    final raw = _prefs.getString(listsKey);
    return raw == null ? const <BroadcastList>[] : BroadcastListDto.decode(raw);
  });

  @override
  Future<Either<Failure, void>> saveLists(List<BroadcastList> lists) =>
      guard(() => _prefs.setString(listsKey, BroadcastListDto.encode(lists)));

  @override
  Future<Either<Failure, DateTime?>> loadLastSentAt() => guard(() async {
    final ms = _prefs.getInt(lastSentAtKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  });

  @override
  Future<Either<Failure, void>> saveLastSentAt(DateTime sentAt) =>
      guard(() => _prefs.setInt(lastSentAtKey, sentAt.millisecondsSinceEpoch));

  @override
  Future<Either<Failure, bool>> loadReminderEnabled() =>
      guard(() async => _prefs.getBool(reminderEnabledKey) ?? true);

  @override
  Future<Either<Failure, void>> saveReminderEnabled(bool enabled) =>
      guard(() => _prefs.setBool(reminderEnabledKey, enabled));
}
