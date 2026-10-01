import 'package:colette/features/baby/domain/entities/bottle_schedule.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/domain/entities/projected_bottle.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';
import 'package:colette/features/dashboard/domain/use_cases/project_bottle_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  const project = ProjectBottleSchedule();
  // 7 h / 23 h 30 / 3 h : 7 biberons par jour.
  const schedule = BottleSchedule();
  // Jour 3 le 10 septembre (100 ml/kg), jour 4 le 11 (120 ml/kg).
  final birth = DateTime(2026, 9, 8);

  FeedingPlan planFor({
    required DateTime now,
    DateTime? lastAt,
    int? override,
  }) {
    final last = lastAt == null
        ? null
        : makeEvent(id: 'b', startAt: lastAt, bottleMl: 60);
    return const ComputeFeedingPlan()(
      birthDate: birth,
      latestWeightGrams: 3600,
      schedule: schedule,
      todayBottles: [?last],
      lastBottle: last,
      now: now,
      dailyTargetMlOverride: override,
    );
  }

  List<ProjectedBottle> projectFor(FeedingPlan plan, DateTime now) => project(
    plan: plan,
    schedule: schedule,
    birthDate: birth,
    latestWeightGrams: 3600,
    now: now,
  );

  List<DateTime> times(List<ProjectedBottle> bottles) => [
    for (final b in bottles) b.at,
  ];

  test('suit l\'intervalle, le biberon du soir puis le matin, sur 24 h', () {
    final now = DateTime(2026, 9, 10, 10);
    final bottles = projectFor(
      planFor(now: now, lastAt: DateTime(2026, 9, 10, 9)),
      now,
    );
    expect(times(bottles), [
      DateTime(2026, 9, 10, 12),
      DateTime(2026, 9, 10, 15),
      DateTime(2026, 9, 10, 18),
      DateTime(2026, 9, 10, 21),
      DateTime(2026, 9, 10, 23, 30),
      DateTime(2026, 9, 11, 7),
    ]);
    // Aujourd'hui : (360 − 60) / 6 = 50. Demain : 430 / 7 = 61,4 → 60.
    expect(bottles.take(5).map((b) => b.suggestedMl), everyElement(50));
    expect(bottles.last.suggestedMl, 60);
  });

  test('journée type après le biberon du soir', () {
    final now = DateTime(2026, 9, 10, 6, 50);
    final bottles = projectFor(
      planFor(now: now, lastAt: DateTime(2026, 9, 9, 23, 30)),
      now,
    );
    expect(times(bottles), [
      DateTime(2026, 9, 10, 7),
      DateTime(2026, 9, 10, 10),
      DateTime(2026, 9, 10, 13),
      DateTime(2026, 9, 10, 16),
      DateTime(2026, 9, 10, 19),
      DateTime(2026, 9, 10, 22),
      DateTime(2026, 9, 10, 23, 30),
    ]);
  });

  test('heure prévue passée : la suite part de maintenant', () {
    final now = DateTime(2026, 9, 10, 10, 15);
    final bottles = projectFor(
      planFor(now: now, lastAt: DateTime(2026, 9, 10, 7)),
      now,
    );
    expect(bottles.first.at, DateTime(2026, 9, 10, 10));
    expect(bottles[1].at, DateTime(2026, 9, 10, 13, 15));
  });

  test('en retard : la suite part de maintenant', () {
    final now = DateTime(2026, 9, 10, 10);
    final bottles = projectFor(
      planFor(now: now, lastAt: DateTime(2026, 9, 10, 4)),
      now,
    );
    expect(bottles.first.at, DateTime(2026, 9, 10, 7));
    expect(bottles[1].at, DateTime(2026, 9, 10, 13));
    expect(bottles.last.at, DateTime(2026, 9, 11, 7));
  });

  test('sans biberon : maintenant, puis selon l\'intervalle', () {
    final now = DateTime(2026, 9, 10, 10);
    final bottles = projectFor(planFor(now: now), now);
    expect(bottles.first.at, now);
    expect(bottles[1].at, DateTime(2026, 9, 10, 13));
  });

  test('cible ajustée pour demain, bornée à 240 ml', () {
    final now = DateTime(2026, 9, 10, 20);
    final bottles = project(
      plan: planFor(
        now: now,
        lastAt: DateTime(2026, 9, 10, 19),
        override: 3000,
      ),
      schedule: schedule,
      birthDate: birth,
      latestWeightGrams: 3600,
      now: now,
      dailyTargetMlOverride: 3000,
    );
    expect(bottles.last.suggestedMl, ComputeFeedingPlan.maxSuggestedMl);
  });

  test('sans pesée, demain suit les repères par âge', () {
    final now = DateTime(2026, 9, 10, 20);
    final plan = const ComputeFeedingPlan()(
      birthDate: DateTime(2026, 9, 6),
      latestWeightGrams: null,
      schedule: schedule,
      todayBottles: const [],
      lastBottle: null,
      now: now,
    );
    final bottles = project(
      plan: plan,
      schedule: schedule,
      birthDate: DateTime(2026, 9, 6),
      latestWeightGrams: null,
      now: now,
    );
    // Jour 6 demain : 480 ml / 7 = 68,6 → 70.
    expect(bottles.last.suggestedMl, 70);
  });
}
