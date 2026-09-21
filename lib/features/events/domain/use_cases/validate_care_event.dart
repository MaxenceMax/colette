import 'package:colette/core/result/failure.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:fpdart/fpdart.dart';

/// Règles de validité d'un événement avant enregistrement.
class ValidateCareEvent {
  const ValidateCareEvent();

  static const minBottleMl = 10;
  static const maxBottleMl = 300;
  static const futureTolerance = Duration(minutes: 5);

  Either<ValidationFailure, CareEvent> call(
    CareEvent event, {
    required DateTime now,
  }) {
    if (event.isEmpty) {
      return left(const ValidationFailure(ValidationReason.emptyEvent));
    }
    if (event.endAt.isBefore(event.startAt)) {
      return left(const ValidationFailure(ValidationReason.endBeforeStart));
    }
    if (event.startAt.isAfter(now.add(futureTolerance))) {
      return left(const ValidationFailure(ValidationReason.startInFuture));
    }
    if (event.bottleMl case final ml?
        when ml < minBottleMl || ml > maxBottleMl) {
      return left(const ValidationFailure(ValidationReason.bottleOutOfRange));
    }
    return right(event);
  }
}
