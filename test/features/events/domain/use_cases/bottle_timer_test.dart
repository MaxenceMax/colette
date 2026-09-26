import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/use_cases/bottle_timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 9, 25, 14);

  final run = BottleTimerRun.startingAt(start);

  BottleTimerPhase at(Duration elapsed, {BottleTimerRun? custom}) =>
      computeBottleTimerPhase(run: custom ?? run, now: start.add(elapsed));

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
    expect(at(const Duration(minutes: 41, seconds: 59)), isA<BottleUpright>());
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

  group('biberon terminé à +10 min', () {
    final early = run.copyWith(
      feedingEndsAt: start.add(const Duration(minutes: 10)),
    );

    test('la verticale dure 12 min à partir de la fin du biberon', () {
      expect(
        at(const Duration(minutes: 10), custom: early),
        isA<BottleUpright>()
            .having(
              (p) => p.remaining,
              'remaining',
              const Duration(minutes: 12),
            )
            .having((p) => p.progress, 'progress', 0),
      );
    });

    test('terminé à +22 min', () {
      expect(
        at(const Duration(minutes: 22), custom: early),
        isA<BottleTimerDone>(),
      );
    });
  });

  group('transitions', () {
    const feeding = BottleFeeding(remaining: Duration.zero, progress: 0);
    const upright = BottleUpright(remaining: Duration.zero, progress: 0);
    const done = BottleTimerDone();

    test('lancement depuis le repos ou après la fin', () {
      expect(
        bottleTimerTransition(null, feeding),
        BottleTimerTransition.started,
      );
      expect(
        bottleTimerTransition(done, feeding),
        BottleTimerTransition.started,
      );
    });

    test('fin du biberon', () {
      expect(
        bottleTimerTransition(feeding, upright),
        BottleTimerTransition.feedingEnded,
      );
    });

    test('fin du minuteur, même en sautant la verticale', () {
      expect(
        bottleTimerTransition(upright, done),
        BottleTimerTransition.finished,
      );
      expect(
        bottleTimerTransition(feeding, done),
        BottleTimerTransition.finished,
      );
    });

    test('arrêt en cours de minuteur', () {
      expect(
        bottleTimerTransition(feeding, null),
        BottleTimerTransition.stopped,
      );
      expect(
        bottleTimerTransition(upright, null),
        BottleTimerTransition.stopped,
      );
    });

    test('aucune transition sans changement de phase ni depuis la fin', () {
      expect(bottleTimerTransition(feeding, feeding), isNull);
      expect(bottleTimerTransition(null, null), isNull);
      expect(bottleTimerTransition(done, null), isNull);
      expect(bottleTimerTransition(done, done), isNull);
    });
  });
}
