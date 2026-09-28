import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/events/data/dtos/bottle_timer_session_dto.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/domain/repositories/bottle_timer_session_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Session du minuteur dans `shared_preferences` (clé [key]).
class PrefsBottleTimerSessionRepository
    implements BottleTimerSessionRepository {
  PrefsBottleTimerSessionRepository(this._prefs);

  static const key = 'bottle_timer_session';

  final SharedPreferences _prefs;

  @override
  Future<Either<Failure, void>> save(BottleTimerSession session) =>
      guard(() => _prefs.setString(key, BottleTimerSessionDto.encode(session)));

  @override
  Future<Either<Failure, BottleTimerSession?>> load() => guard(() async {
    final raw = _prefs.getString(key);
    return raw == null ? null : BottleTimerSessionDto.decode(raw);
  });

  @override
  Future<Either<Failure, void>> clear() => guard(() => _prefs.remove(key));
}
