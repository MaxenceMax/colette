import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';
import 'package:colette/features/dashboard/domain/use_cases/project_bottle_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  const project = ProjectBottleSchedule();
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
      feedsPerDay: 8,
      todayBottles: [?last],
      lastBottle: last,
      now: now,
      dailyTargetMlOverride: override,
    );
  }

  test('8 prises : le prochain puis toutes les 3 h jusqu\'à 24 h', () {
    final now = DateTime(2026, 9, 10, 10);
    final bottles = project(
      plan: planFor(now: now, lastAt: DateTime(2026, 9, 10, 9)),
      birthDate: birth,
      latestWeightGrams: 3600,
      now: now,
    );
    expect(
      [for (final b in bottles) b.at],
      [
        DateTime(2026, 9, 10, 12),
        DateTime(2026, 9, 10, 15),
        DateTime(2026, 9, 10, 18),
        DateTime(2026, 9, 10, 21),
        DateTime(2026, 9, 11, 0),
        DateTime(2026, 9, 11, 3),
        DateTime(2026, 9, 11, 6),
        DateTime(2026, 9, 11, 9),
      ],
    );
    expect(bottles.first.windowStart, DateTime(2026, 9, 10, 11, 35));
    expect(bottles.first.windowEnd, DateTime(2026, 9, 10, 12, 25));
    expect(bottles[1].windowStart, DateTime(2026, 9, 10, 14, 35));
    expect(bottles[1].windowEnd, DateTime(2026, 9, 10, 15, 25));
    // Aujourd'hui : (360 − 60) / 7 = 42,9 → 40. Demain : 430 / 8 = 53,8 → 50.
    expect(bottles.take(4).map((b) => b.suggestedMl), everyElement(40));
    expect(bottles.skip(4).map((b) => b.suggestedMl), everyElement(50));
  });

  test('en retard : la suite repart de maintenant', () {
    final now = DateTime(2026, 9, 10, 10);
    final bottles = project(
      plan: planFor(now: now, lastAt: DateTime(2026, 9, 10, 6)),
      birthDate: birth,
      latestWeightGrams: 3600,
      now: now,
    );
    expect(bottles.first.at, DateTime(2026, 9, 10, 9));
    expect(bottles[1].at, DateTime(2026, 9, 10, 13));
    expect(bottles.last.at, DateTime(2026, 9, 11, 7));
  });

  test('sans biberon : maintenant, puis dans 3 h', () {
    final now = DateTime(2026, 9, 10, 10);
    final bottles = project(
      plan: planFor(now: now),
      birthDate: birth,
      latestWeightGrams: 3600,
      now: now,
    );
    expect(bottles.first.windowStart, now);
    expect(bottles.first.windowEnd, now);
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
      feedsPerDay: 8,
      todayBottles: const [],
      lastBottle: null,
      now: now,
    );
    final bottles = project(
      plan: plan,
      birthDate: DateTime(2026, 9, 6),
      latestWeightGrams: null,
      now: now,
    );
    // Jour 6 demain : 480 ml / 8 = 60.
    expect(bottles.last.suggestedMl, 60);
  });
}
