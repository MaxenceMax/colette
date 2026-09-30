import 'package:colette/features/baby/domain/entities/bottle_schedule.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  const compute = ComputeFeedingPlan();
  final birth = DateTime(2026, 9, 1, 6);
  const schedule = BottleSchedule();
  // 7 h → 22 h toutes les 5 h : 4 biberons par jour.
  const fourFeeds = BottleSchedule(
    lastBottle: Duration(hours: 22),
    interval: Duration(hours: 5),
  );

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
    'jour 10, 3 600 g, 2 biberons de 60 : cible 540, reste 420 sur 5 prises',
    () {
      final now = DateTime(2026, 9, 10, 12);
      final bottles = [
        makeEvent(id: 'a', startAt: DateTime(2026, 9, 10, 6), bottleMl: 60),
        makeEvent(id: 'b', startAt: DateTime(2026, 9, 10, 9), bottleMl: 60),
      ];
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 3600,
        schedule: schedule,
        todayBottles: bottles,
        lastBottle: bottles.last,
        now: now,
      );
      expect(plan.dailyTargetMl, 540);
      expect(plan.isEstimatedFromAge, isFalse);
      expect(plan.feedsPerDay, 7);
      expect(plan.bottlesGiven, 2);
      expect(plan.bottlesRemaining, 5);
      expect(plan.givenMl, 120);
      expect(plan.remainingMl, 420);
      // 420 / 5 = 84 → 80.
      expect(plan.suggestedMl, 80);
      expect(plan.nextBottleAt, DateTime(2026, 9, 10, 12));
      expect(plan.lateBy(now), Duration.zero);
    },
  );

  test('sans biberon, le prochain est maintenant et la suggestion vaut cible / prises', () {
    final now = DateTime(2026, 9, 1, 12);
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: 3500,
      schedule: schedule,
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
      schedule: schedule,
      todayBottles: const [],
      lastBottle: null,
      now: DateTime(2026, 9, 20, 12),
    );
    expect(plan.dailyTargetMl, 480);
    expect(plan.isEstimatedFromAge, isTrue);
    // 480 / 7 = 68,6 → 70.
    expect(plan.suggestedMl, 70);
  });

  test('le retard est compté depuis la fin de la fourchette', () {
    // 6 h est un biberon de nuit : matin 7 h, mais 6 h + 3 h = 9 h plus tard.
    final last = makeEvent(
      id: 'a',
      startAt: DateTime(2026, 9, 10, 6),
      bottleMl: 90,
    );
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: 3600,
      schedule: schedule,
      todayBottles: [last],
      lastBottle: last,
      now: DateTime(2026, 9, 10, 10),
    );
    expect(plan.nextBottleAt, DateTime(2026, 9, 10, 9));
    expect(plan.windowEnd, DateTime(2026, 9, 10, 9, 30));
    expect(plan.hasWindow, isTrue);
    expect(plan.lateBy(DateTime(2026, 9, 10, 9, 30)), Duration.zero);
    expect(
      plan.lateBy(DateTime(2026, 9, 10, 10, 5)),
      const Duration(minutes: 35),
    );
  });

  group('fourchette', () {
    (DateTime, DateTime) windowFor(DateTime last) {
      final bottle = makeEvent(id: 'a', startAt: last, bottleMl: 60);
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 3600,
        schedule: schedule,
        todayBottles: [bottle],
        lastBottle: bottle,
        now: last,
      );
      return (plan.windowStart, plan.windowEnd);
    }

    test('de 30 min avant à 30 min après l\'heure prévue', () {
      expect(windowFor(DateTime(2026, 9, 10, 10)), (
        DateTime(2026, 9, 10, 12, 30),
        DateTime(2026, 9, 10, 13, 30),
      ));
    });

    test('biberon de 22 h : fourchette du soir autour de 23 h 30', () {
      expect(windowFor(DateTime(2026, 9, 10, 22)), (
        DateTime(2026, 9, 10, 23),
        DateTime(2026, 9, 11, 0),
      ));
    });

    test('biberon du soir : fourchette du matin, 6 h 30 – 7 h 30', () {
      expect(windowFor(DateTime(2026, 9, 10, 23, 10)), (
        DateTime(2026, 9, 11, 6, 30),
        DateTime(2026, 9, 11, 7, 30),
      ));
    });

    test('ouverte 30 min avant l\'heure prévue, fermée 30 min après', () {
      final last = makeEvent(
        id: 'a',
        startAt: DateTime(2026, 9, 10, 10),
        bottleMl: 60,
      );
      FeedingPlan at(DateTime now) => compute(
        birthDate: birth,
        latestWeightGrams: 3600,
        schedule: schedule,
        todayBottles: [last],
        lastBottle: last,
        now: now,
      );
      expect(
        at(DateTime(2026, 9, 10, 12, 29)).isOpen(DateTime(2026, 9, 10, 12, 29)),
        isFalse,
      );
      expect(
        at(DateTime(2026, 9, 10, 12, 30)).isOpen(DateTime(2026, 9, 10, 12, 30)),
        isTrue,
      );
      expect(
        at(DateTime(2026, 9, 10, 13, 30)).isOpen(DateTime(2026, 9, 10, 13, 30)),
        isTrue,
      );
      expect(
        at(DateTime(2026, 9, 10, 13, 31)).isOpen(DateTime(2026, 9, 10, 13, 31)),
        isFalse,
      );
    });

    test('sans biberon : fourchette réduite à maintenant', () {
      final now = DateTime(2026, 9, 10, 12, 3);
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 3600,
        schedule: schedule,
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
      schedule: fourFeeds,
      todayBottles: const [],
      lastBottle: null,
      now: DateTime(2026, 12, 10, 12),
    );
    expect(high.suggestedMl, 240);
  });

  test('toutes les prises données : suggestion = cible / prises', () {
    final bottles = List.generate(
      7,
      (i) => makeEvent(
        id: '$i',
        startAt: DateTime(2026, 9, 10, i * 2),
        bottleMl: 60,
      ),
    );
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: 3600,
      schedule: schedule,
      todayBottles: bottles,
      lastBottle: bottles.last,
      now: DateTime(2026, 9, 10, 16),
    );
    expect(plan.bottlesRemaining, 0);
    // 540 / 7 = 77,1 → 80.
    expect(plan.suggestedMl, 80);
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
        schedule: schedule,
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
      // 540 / 6 = 90.
      expect(plan.suggestedMl, 90);
    });

    test('sans override, la cible effective est la cible OMS', () {
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 4200,
        schedule: schedule,
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
        schedule: schedule,
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
        schedule: schedule,
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
          schedule: schedule,
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
        schedule: fourFeeds,
        todayBottles: const [],
        lastBottle: null,
        now: DateTime(2026, 9, 10, 12),
        dailyTargetMlOverride: 1500,
      );
      expect(plan.suggestedMl, ComputeFeedingPlan.maxSuggestedMl);
    });
  });
}
