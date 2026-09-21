import 'package:colette/core/result/failure.dart';
import 'package:colette/features/events/domain/use_cases/validate_care_event.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/care_event_factory.dart';

void main() {
  const validate = ValidateCareEvent();
  final now = DateTime(2026, 9, 21, 14, 30);

  ValidationReason? reasonOf(Object? result) =>
      result is ValidationFailure ? result.reason : null;

  test('refuse un événement vide', () {
    final result = validate(makeEvent(startAt: now), now: now);
    expect(
      reasonOf(result.getLeft().toNullable()),
      ValidationReason.emptyEvent,
    );
  });

  test('refuse une fin avant le début', () {
    final event = makeEvent(
      startAt: now,
      endAt: now.subtract(const Duration(minutes: 5)),
      pee: true,
    );
    final result = validate(event, now: now);
    expect(
      reasonOf(result.getLeft().toNullable()),
      ValidationReason.endBeforeStart,
    );
  });

  test('refuse un début dans le futur au-delà de la tolérance', () {
    final event = makeEvent(
      startAt: now.add(const Duration(minutes: 10)),
      pee: true,
    );
    final result = validate(event, now: now);
    expect(
      reasonOf(result.getLeft().toNullable()),
      ValidationReason.startInFuture,
    );
  });

  test('tolère un début 5 minutes dans le futur', () {
    final event = makeEvent(
      startAt: now.add(const Duration(minutes: 5)),
      pee: true,
    );
    expect(validate(event, now: now).isRight(), isTrue);
  });

  test('refuse un biberon hors bornes', () {
    expect(
      reasonOf(
        validate(
          makeEvent(startAt: now, bottleMl: 5),
          now: now,
        ).getLeft().toNullable(),
      ),
      ValidationReason.bottleOutOfRange,
    );
    expect(
      reasonOf(
        validate(
          makeEvent(startAt: now, bottleMl: 310),
          now: now,
        ).getLeft().toNullable(),
      ),
      ValidationReason.bottleOutOfRange,
    );
  });

  test('accepte un biberon seul de 120 ml', () {
    expect(
      validate(makeEvent(startAt: now, bottleMl: 120), now: now).isRight(),
      isTrue,
    );
  });
}
