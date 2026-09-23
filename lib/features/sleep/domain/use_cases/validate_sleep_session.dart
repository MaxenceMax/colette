import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:fpdart/fpdart.dart';

/// Règles de validité d'un sommeil avant enregistrement.
class ValidateSleepSession {
  const ValidateSleepSession();

  static const futureTolerance = Duration(minutes: 1);
  static const maxDuration = Duration(hours: 24);

  /// Fin utilisée pour un sommeil en cours dans le test de chevauchement.
  static final _openEnd = DateTime(9999);

  Either<Failure, SleepSession> call(
    SleepSession session, {
    required DateTime now,
    required DateTime birthDate,
    required List<SleepSession> others,
  }) {
    final end = session.endAt;
    if (end != null && !end.isAfter(session.startAt)) {
      return left(const ValidationFailure(ValidationReason.endBeforeStart));
    }
    final limit = now.add(futureTolerance);
    if (session.startAt.isAfter(limit) || (end != null && end.isAfter(limit))) {
      return left(const ValidationFailure(ValidationReason.sleepInFuture));
    }
    if (session.durationUntil(now) > maxDuration) {
      return left(const ValidationFailure(ValidationReason.sleepTooLong));
    }
    if (session.startAt.isBefore(birthDate.dateOnly)) {
      return left(const ValidationFailure(ValidationReason.sleepBeforeBirth));
    }
    final sessionEnd = end ?? _openEnd;
    for (final other in others) {
      if (other.id == session.id) continue;
      // Deux sommeils en cours ne peuvent être que des doublons d'un double
      // appui, nettoyés au réveil par planWakeUp : on les ignore entre eux.
      if (end == null && other.endAt == null) continue;
      final otherEnd = other.endAt ?? _openEnd;
      if (session.startAt.isBefore(otherEnd) &&
          other.startAt.isBefore(sessionEnd)) {
        return left(
          SleepOverlapFailure(startAt: other.startAt, endAt: other.endAt),
        );
      }
    }
    return right(session);
  }
}
