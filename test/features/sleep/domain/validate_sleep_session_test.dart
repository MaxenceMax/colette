import 'package:colette/core/result/failure.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/use_cases/validate_sleep_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sleep_session_factory.dart';

void main() {
  const validate = ValidateSleepSession();
  final now = DateTime(2026, 9, 23, 16);
  final birth = DateTime(2026, 9, 1);

  Object? failureOf(
    SleepSession sleep, {
    List<SleepSession> others = const [],
  }) => validate(
    sleep,
    now: now,
    birthDate: birth,
    others: others,
  ).getLeft().toNullable();

  test('accepte un sommeil terminé valide', () {
    final sleep = makeSleep(
      startAt: DateTime(2026, 9, 23, 13),
      endAt: DateTime(2026, 9, 23, 14),
    );
    expect(
      validate(sleep, now: now, birthDate: birth, others: const []).isRight(),
      isTrue,
    );
  });

  test('refuse une fin avant ou égale au début', () {
    final at = DateTime(2026, 9, 23, 13);
    expect(
      failureOf(makeSleep(startAt: at, endAt: at)),
      isA<ValidationFailure>().having(
        (f) => f.reason,
        'reason',
        ValidationReason.endBeforeStart,
      ),
    );
  });

  test('refuse un début ou une fin dans le futur, tolère 1 min', () {
    expect(
      failureOf(
        makeSleep(
          startAt: DateTime(2026, 9, 23, 15),
          endAt: now.add(const Duration(minutes: 1)),
        ),
      ),
      isNull,
    );
    expect(
      failureOf(
        makeSleep(
          startAt: DateTime(2026, 9, 23, 15),
          endAt: now.add(const Duration(minutes: 2)),
        ),
      ),
      isA<ValidationFailure>().having(
        (f) => f.reason,
        'reason',
        ValidationReason.sleepInFuture,
      ),
    );
    expect(
      failureOf(makeSleep(startAt: now.add(const Duration(minutes: 5)))),
      isA<ValidationFailure>().having(
        (f) => f.reason,
        'reason',
        ValidationReason.sleepInFuture,
      ),
    );
  });

  test('refuse plus de 24 h, y compris un sommeil en cours', () {
    expect(
      failureOf(
        makeSleep(
          startAt: DateTime(2026, 9, 22, 15),
          endAt: DateTime(2026, 9, 23, 15, 1),
        ),
      ),
      isA<ValidationFailure>().having(
        (f) => f.reason,
        'reason',
        ValidationReason.sleepTooLong,
      ),
    );
    expect(
      failureOf(makeSleep(startAt: DateTime(2026, 9, 22, 15))),
      isA<ValidationFailure>().having(
        (f) => f.reason,
        'reason',
        ValidationReason.sleepTooLong,
      ),
    );
  });

  test('refuse un début avant la naissance', () {
    expect(
      failureOf(
        makeSleep(
          startAt: DateTime(2026, 8, 31, 23),
          endAt: DateTime(2026, 9, 1, 1),
        ),
      ),
      isA<ValidationFailure>().having(
        (f) => f.reason,
        'reason',
        ValidationReason.sleepBeforeBirth,
      ),
    );
  });

  test('refuse un chevauchement et porte les heures du conflit', () {
    final other = makeSleep(
      id: 'o',
      startAt: DateTime(2026, 9, 23, 14, 10),
      endAt: DateTime(2026, 9, 23, 15, 30),
    );
    final sleep = makeSleep(
      startAt: DateTime(2026, 9, 23, 15),
      endAt: DateTime(2026, 9, 23, 15, 45),
    );
    expect(
      failureOf(sleep, others: [other]),
      SleepOverlapFailure(startAt: other.startAt, endAt: other.endAt),
    );
  });

  test('accepte deux sommeils bord à bord et ignore le sommeil lui-même', () {
    final other = makeSleep(
      id: 'o',
      startAt: DateTime(2026, 9, 23, 13),
      endAt: DateTime(2026, 9, 23, 14),
    );
    final sleep = makeSleep(
      id: 's',
      startAt: DateTime(2026, 9, 23, 14),
      endAt: DateTime(2026, 9, 23, 15),
    );
    expect(failureOf(sleep, others: [other, sleep]), isNull);
  });

  test('un sommeil en cours chevauche tout sommeil qui commence après lui', () {
    final ongoing = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 12));
    final sleep = makeSleep(
      startAt: DateTime(2026, 9, 23, 14),
      endAt: DateTime(2026, 9, 23, 15),
    );
    expect(
      failureOf(sleep, others: [ongoing]),
      SleepOverlapFailure(startAt: ongoing.startAt),
    );
  });

  test('une session en cours ignore les autres sommeils en cours', () {
    final other = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 14));
    final sleep = makeSleep(id: 's', startAt: DateTime(2026, 9, 23, 15));
    expect(failureOf(sleep, others: [other]), isNull);
  });

  test(
    'une session en cours refuse un sommeil terminé qui commence après elle',
    () {
      final other = makeSleep(
        id: 'o',
        startAt: DateTime(2026, 9, 23, 15, 30),
        endAt: DateTime(2026, 9, 23, 15, 45),
      );
      final sleep = makeSleep(id: 's', startAt: DateTime(2026, 9, 23, 15));
      expect(
        failureOf(sleep, others: [other]),
        SleepOverlapFailure(startAt: other.startAt, endAt: other.endAt),
      );
    },
  );

  test('un sommeil qui en contient un autre est un chevauchement', () {
    final other = makeSleep(
      id: 'o',
      startAt: DateTime(2026, 9, 23, 13),
      endAt: DateTime(2026, 9, 23, 15),
    );
    final sleep = makeSleep(
      startAt: DateTime(2026, 9, 23, 13, 30),
      endAt: DateTime(2026, 9, 23, 14),
    );
    expect(
      failureOf(sleep, others: [other]),
      SleepOverlapFailure(startAt: other.startAt, endAt: other.endAt),
    );
  });

  test('un sommeil contenu dans un autre est un chevauchement', () {
    final other = makeSleep(
      id: 'o',
      startAt: DateTime(2026, 9, 23, 13, 30),
      endAt: DateTime(2026, 9, 23, 14),
    );
    final sleep = makeSleep(
      startAt: DateTime(2026, 9, 23, 13),
      endAt: DateTime(2026, 9, 23, 15),
    );
    expect(
      failureOf(sleep, others: [other]),
      SleepOverlapFailure(startAt: other.startAt, endAt: other.endAt),
    );
  });

  test(
    'bord à bord inverse : la fin du sommeil correspond au début de l\'autre',
    () {
      final other = makeSleep(
        id: 'o',
        startAt: DateTime(2026, 9, 23, 14),
        endAt: DateTime(2026, 9, 23, 15),
      );
      final sleep = makeSleep(
        startAt: DateTime(2026, 9, 23, 13),
        endAt: DateTime(2026, 9, 23, 14),
      );
      expect(failureOf(sleep, others: [other]), isNull);
    },
  );

  test('accepte exactement 24 h', () {
    final sleep = makeSleep(
      startAt: DateTime(2026, 9, 22, 16),
      endAt: DateTime(2026, 9, 23, 16),
    );
    expect(failureOf(sleep), isNull);
  });

  test('accepte un début à 00:00 le jour de naissance', () {
    final sleep = makeSleep(
      startAt: DateTime(2026, 9, 1),
      endAt: DateTime(2026, 9, 1, 1),
    );
    expect(failureOf(sleep), isNull);
  });

  test('accepte une nuit de 22 h à 6 h le lendemain', () {
    final sleep = makeSleep(
      startAt: DateTime(2026, 9, 22, 22),
      endAt: DateTime(2026, 9, 23, 6),
    );
    expect(failureOf(sleep), isNull);
  });
}
