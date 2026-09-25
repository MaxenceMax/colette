import 'package:colette/features/events/domain/use_cases/bottle_timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 9, 25, 14);

  BottleTimerPhase at(Duration elapsed) =>
      computeBottleTimerPhase(startedAt: start, now: start.add(elapsed));

  test('au départ : biberon, 30 min restantes, progression nulle', () {
    expect(
      at(Duration.zero),
      isA<BottleFeeding>()
          .having((p) => p.remaining, 'remaining', const Duration(minutes: 30))
          .having((p) => p.progress, 'progress', 0),
    );
  });

  test('à 29:59 : encore biberon, 1 s restante', () {
    expect(
      at(const Duration(minutes: 29, seconds: 59)),
      isA<BottleFeeding>().having(
        (p) => p.remaining,
        'remaining',
        const Duration(seconds: 1),
      ),
    );
  });

  test('à 15 min : biberon à mi-parcours', () {
    expect(
      at(const Duration(minutes: 15)),
      isA<BottleFeeding>().having((p) => p.progress, 'progress', 0.5),
    );
  });

  test('à 30:00 : verticale, 12 min restantes', () {
    expect(
      at(const Duration(minutes: 30)),
      isA<BottleUpright>()
          .having((p) => p.remaining, 'remaining', const Duration(minutes: 12))
          .having((p) => p.progress, 'progress', 0),
    );
  });

  test('à 36 min : verticale à mi-parcours', () {
    expect(
      at(const Duration(minutes: 36)),
      isA<BottleUpright>().having((p) => p.progress, 'progress', 0.5),
    );
  });

  test('à 41:59 : encore verticale', () {
    expect(
      at(const Duration(minutes: 41, seconds: 59)),
      isA<BottleUpright>(),
    );
  });

  test('à 42:00 : terminé', () {
    expect(at(const Duration(minutes: 42)), isA<BottleTimerDone>());
  });

  test('une horloge antérieure au départ compte comme le départ', () {
    expect(
      at(const Duration(minutes: -5)),
      isA<BottleFeeding>().having(
        (p) => p.remaining,
        'remaining',
        const Duration(minutes: 30),
      ),
    );
  });
}
