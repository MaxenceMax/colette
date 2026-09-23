import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  const compute = ComputeFeedingPlan();
  final birth = DateTime(2026, 9, 1, 6);

  group('règles OMS', () {
    test('jour de vie : 1 le jour de la naissance', () {
      expect(ComputeFeedingPlan.dayOfLife(birth, DateTime(2026, 9, 1, 23)), 1);
      expect(
        ComputeFeedingPlan.dayOfLife(birth, DateTime(2026, 9, 2, 0, 5)),
        2,
      );
      expect(ComputeFeedingPlan.dayOfLife(birth, DateTime(2026, 8, 31)), 1);
    });

    test(
      'jour de vie : jours civils, insensible au changement d\'heure (DST)',
      () {
        // Passage à l'heure d'été le 29 mars 2026 entre les deux dates.
        expect(
          ComputeFeedingPlan.dayOfLife(
            DateTime(2026, 3, 20),
            DateTime(2026, 3, 30, 12),
          ),
          11,
        );
        expect(
          ComputeFeedingPlan.dayOfLife(
            DateTime(2026, 3, 20),
            DateTime(2026, 10, 26),
          ),
          221,
        );
      },
    );

    test('ml par kg : 60 le jour 1, +20 par jour, plafonné à 150', () {
      expect(ComputeFeedingPlan.mlPerKg(1), 60);
      expect(ComputeFeedingPlan.mlPerKg(3), 100);
      expect(ComputeFeedingPlan.mlPerKg(6), 150);
      expect(ComputeFeedingPlan.mlPerKg(40), 150);
    });

    test('mlPerKgPlateauDay est le jour où le plafond de 150 est atteint', () {
      expect(
        ComputeFeedingPlan.mlPerKg(ComputeFeedingPlan.mlPerKgPlateauDay - 1),
        lessThan(
          ComputeFeedingPlan.mlPerKg(ComputeFeedingPlan.mlPerKgPlateauDay),
        ),
      );
      expect(
        ComputeFeedingPlan.mlPerKg(ComputeFeedingPlan.mlPerKgPlateauDay),
        ComputeFeedingPlan.mlPerKg(ComputeFeedingPlan.mlPerKgPlateauDay + 1),
      );
    });

    test('repères par âge sans pesée', () {
      expect(ComputeFeedingPlan.dailyTargetFromAge(1), 240);
      expect(ComputeFeedingPlan.dailyTargetFromAge(5), 480);
      expect(ComputeFeedingPlan.dailyTargetFromAge(20), 480);
      expect(ComputeFeedingPlan.dailyTargetFromAge(45), 630);
      expect(ComputeFeedingPlan.dailyTargetFromAge(100), 720);
      expect(ComputeFeedingPlan.dailyTargetFromAge(150), 900);
    });
  });

  test(
    'jour 10, 3 600 g, 2 biberons de 60 : cible 540, reste 420 sur 6 prises',
    () {
      final now = DateTime(2026, 9, 10, 12);
      final bottles = [
        makeEvent(id: 'a', startAt: DateTime(2026, 9, 10, 6), bottleMl: 60),
        makeEvent(id: 'b', startAt: DateTime(2026, 9, 10, 9), bottleMl: 60),
      ];
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 3600,
        feedsPerDay: 8,
        todayBottles: bottles,
        lastBottle: bottles.last,
        now: now,
      );
      expect(plan.dailyTargetMl, 540);
      expect(plan.isEstimatedFromAge, isFalse);
      expect(plan.bottlesGiven, 2);
      expect(plan.bottlesRemaining, 6);
      expect(plan.givenMl, 120);
      expect(plan.remainingMl, 420);
      expect(plan.suggestedMl, 70);
      expect(plan.nextBottleAt, DateTime(2026, 9, 10, 12));
      expect(plan.lateBy(now), Duration.zero);
    },
  );

  test('sans biberon, le prochain est maintenant et la suggestion vaut cible / prises', () {
    final now = DateTime(2026, 9, 1, 12);
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: 3500,
      feedsPerDay: 8,
      todayBottles: const [],
      lastBottle: null,
      now: now,
    );
    expect(plan.dailyTargetMl, 210);
    expect(plan.nextBottleAt, now);
    expect(plan.suggestedMl, 30);
  });

  test('sans pesée, la cible vient des repères par âge', () {
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: null,
      feedsPerDay: 8,
      todayBottles: const [],
      lastBottle: null,
      now: DateTime(2026, 9, 20, 12),
    );
    expect(plan.dailyTargetMl, 480);
    expect(plan.isEstimatedFromAge, isTrue);
    expect(plan.suggestedMl, 60);
  });

  test('le retard est compté depuis la fin de la fourchette', () {
    final last = makeEvent(
      id: 'a',
      startAt: DateTime(2026, 9, 10, 6),
      bottleMl: 90,
    );
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: 3600,
      feedsPerDay: 8,
      todayBottles: [last],
      lastBottle: last,
      now: DateTime(2026, 9, 10, 10),
    );
    expect(plan.nextBottleAt, DateTime(2026, 9, 10, 9));
    expect(plan.windowEnd, DateTime(2026, 9, 10, 11));
    expect(plan.hasWindow, isTrue);
    expect(plan.lateBy(DateTime(2026, 9, 10, 10)), Duration.zero);
    expect(
      plan.lateBy(DateTime(2026, 9, 10, 11, 35)),
      const Duration(minutes: 35),
    );
  });

  group('fourchette', () {
    (DateTime, DateTime) windowFor(int feeds, DateTime last) {
      final bottle = makeEvent(id: 'a', startAt: last, bottleMl: 60);
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 3600,
        feedsPerDay: feeds,
        todayBottles: [bottle],
        lastBottle: bottle,
        now: last,
      );
      return (plan.windowStart, plan.windowEnd);
    }

    test('de 2 h 30 à 5 h après le dernier, quel que soit le rythme', () {
      expect(windowFor(8, DateTime(2026, 9, 10, 5, 10)), (
        DateTime(2026, 9, 10, 7, 40),
        DateTime(2026, 9, 10, 10, 10),
      ));
      expect(windowFor(6, DateTime(2026, 9, 10, 6)), (
        DateTime(2026, 9, 10, 8, 30),
        DateTime(2026, 9, 10, 11),
      ));
    });

    test('ouverte dès 2 h 30 après le dernier biberon', () {
      final last = makeEvent(
        id: 'a',
        startAt: DateTime(2026, 9, 10, 6),
        bottleMl: 60,
      );
      FeedingPlan at(DateTime now) => compute(
        birthDate: birth,
        latestWeightGrams: 3600,
        feedsPerDay: 8,
        todayBottles: [last],
        lastBottle: last,
        now: now,
      );
      expect(
        at(DateTime(2026, 9, 10, 8, 29)).isOpen(DateTime(2026, 9, 10, 8, 29)),
        isFalse,
      );
      expect(
        at(DateTime(2026, 9, 10, 8, 30)).isOpen(DateTime(2026, 9, 10, 8, 30)),
        isTrue,
      );
      expect(
        at(DateTime(2026, 9, 10, 11)).isOpen(DateTime(2026, 9, 10, 11)),
        isTrue,
      );
      expect(
        at(DateTime(2026, 9, 10, 11, 1)).isOpen(DateTime(2026, 9, 10, 11, 1)),
        isFalse,
      );
    });

    test('sans biberon : fourchette réduite à maintenant', () {
      final now = DateTime(2026, 9, 10, 12, 3);
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 3600,
        feedsPerDay: 8,
        todayBottles: const [],
        lastBottle: null,
        now: now,
      );
      expect(plan.windowStart, now);
      expect(plan.windowEnd, now);
      expect(plan.hasWindow, isFalse);
      expect(plan.isOpen(now), isFalse);
    });
  });

  test('la suggestion est bornée entre 30 et 240 ml', () {
    final high = compute(
      birthDate: birth,
      latestWeightGrams: 8000,
      feedsPerDay: 4,
      todayBottles: const [],
      lastBottle: null,
      now: DateTime(2026, 12, 10, 12),
    );
    expect(high.suggestedMl, 240);
  });

  test('toutes les prises données : suggestion = cible / prises', () {
    final bottles = List.generate(
      8,
      (i) => makeEvent(
        id: '$i',
        startAt: DateTime(2026, 9, 10, i * 2),
        bottleMl: 60,
      ),
    );
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: 3600,
      feedsPerDay: 8,
      todayBottles: bottles,
      lastBottle: bottles.last,
      now: DateTime(2026, 9, 10, 16),
    );
    expect(plan.bottlesRemaining, 0);
    expect(plan.suggestedMl, 70);
  });

  test('feedsPerDay à 0 est traité comme 1 sans planter', () {
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: 3600,
      feedsPerDay: 0,
      todayBottles: const [],
      lastBottle: null,
      now: DateTime(2026, 9, 10, 12),
    );
    expect(plan.feedsPerDay, 1);
    expect(plan.suggestedMl, 240);
  });

  group('cible ajustée', () {
    test('remplace la cible OMS et pilote la suggestion', () {
      final bottle = makeEvent(
        id: 'a',
        startAt: DateTime(2026, 9, 10, 9),
        bottleMl: 60,
      );
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 4200,
        feedsPerDay: 8,
        todayBottles: [bottle],
        lastBottle: bottle,
        now: DateTime(2026, 9, 10, 12),
        dailyTargetMlOverride: 600,
      );
      expect(plan.dailyTargetMl, 600);
      expect(plan.omsTargetMl, 630);
      expect(plan.isTargetOverridden, isTrue);
      expect(plan.isEstimatedFromAge, isFalse);
      expect(plan.remainingMl, 540);
      // 540 / 7 = 77,1 → 80.
      expect(plan.suggestedMl, 80);
    });

    test('sans override, la cible effective est la cible OMS', () {
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 4200,
        feedsPerDay: 8,
        todayBottles: const [],
        lastBottle: null,
        now: DateTime(2026, 9, 10, 12),
      );
      expect(plan.dailyTargetMl, 630);
      expect(plan.omsTargetMl, 630);
      expect(plan.isTargetOverridden, isFalse);
    });

    test('override sans pesée : estimé par âge mais cible forcée', () {
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: null,
        feedsPerDay: 8,
        todayBottles: const [],
        lastBottle: null,
        now: DateTime(2026, 9, 20, 12),
        dailyTargetMlOverride: 600,
      );
      expect(plan.dailyTargetMl, 600);
      expect(plan.omsTargetMl, 480);
      expect(plan.isEstimatedFromAge, isTrue);
      expect(plan.isTargetOverridden, isTrue);
    });

    test('override égal à la cible OMS : toujours signalé comme ajusté', () {
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 4200,
        feedsPerDay: 8,
        todayBottles: const [],
        lastBottle: null,
        now: DateTime(2026, 9, 10, 12),
        dailyTargetMlOverride: 630,
      );
      expect(plan.dailyTargetMl, plan.omsTargetMl);
      expect(plan.isTargetOverridden, isTrue);
    });

    test(
      'override inférieur aux ml déjà donnés : reste 0, suggestion plancher 30',
      () {
        final bottle = makeEvent(
          id: 'a',
          startAt: DateTime(2026, 9, 10, 9),
          bottleMl: 200,
        );
        final plan = compute(
          birthDate: birth,
          latestWeightGrams: 4200,
          feedsPerDay: 8,
          todayBottles: [bottle],
          lastBottle: bottle,
          now: DateTime(2026, 9, 10, 12),
          dailyTargetMlOverride: 100,
        );
        expect(plan.remainingMl, 0);
        expect(plan.suggestedMl, ComputeFeedingPlan.minSuggestedMl);
      },
    );

    test('override très haut : la suggestion reste plafonnée à 240', () {
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 4200,
        feedsPerDay: 4,
        todayBottles: const [],
        lastBottle: null,
        now: DateTime(2026, 9, 10, 12),
        dailyTargetMlOverride: 1500,
      );
      expect(plan.suggestedMl, ComputeFeedingPlan.maxSuggestedMl);
    });
  });
}
