import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/domain/entities/projected_bottle.dart';
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

  List<DateTime> starts(List<ProjectedBottle> bottles) => [
    for (final b in bottles) b.windowStart,
  ];

  test('chaque fourchette part au plus tôt de la précédente, sur 24 h', () {
    final now = DateTime(2026, 9, 10, 10);
    final bottles = project(
      plan: planFor(now: now, lastAt: DateTime(2026, 9, 10, 9)),
      birthDate: birth,
      latestWeightGrams: 3600,
      now: now,
    );
    expect(starts(bottles), [
      DateTime(2026, 9, 10, 11, 30),
      DateTime(2026, 9, 10, 14),
      DateTime(2026, 9, 10, 16, 30),
      DateTime(2026, 9, 10, 19),
      DateTime(2026, 9, 10, 21, 30),
      DateTime(2026, 9, 11, 0),
      DateTime(2026, 9, 11, 2, 30),
      DateTime(2026, 9, 11, 5),
      DateTime(2026, 9, 11, 7, 30),
    ]);
    expect(bottles.first.windowEnd, DateTime(2026, 9, 10, 14));
    for (final b in bottles.skip(1)) {
      expect(
        b.windowEnd,
        b.windowStart.add(const Duration(hours: 2, minutes: 30)),
      );
      expect(b.at, b.windowStart);
    }
    // Aujourd'hui : (360 − 60) / 7 = 42,9 → 40. Demain : 430 / 8 = 53,8 → 50.
    expect(bottles.take(5).map((b) => b.suggestedMl), everyElement(40));
    expect(bottles.skip(5).map((b) => b.suggestedMl), everyElement(50));
  });

  test('fourchette ouverte : la suite part de maintenant', () {
    final now = DateTime(2026, 9, 10, 10);
    final bottles = project(
      plan: planFor(now: now, lastAt: DateTime(2026, 9, 10, 6)),
      birthDate: birth,
      latestWeightGrams: 3600,
      now: now,
    );
    expect(bottles.first.windowStart, DateTime(2026, 9, 10, 8, 30));
    expect(bottles[1].windowStart, DateTime(2026, 9, 10, 12, 30));
    expect(bottles[1].windowEnd, DateTime(2026, 9, 10, 15));
  });

  test('en retard : la suite part de maintenant', () {
    final now = DateTime(2026, 9, 10, 10);
    final bottles = project(
      plan: planFor(now: now, lastAt: DateTime(2026, 9, 10, 4)),
      birthDate: birth,
      latestWeightGrams: 3600,
      now: now,
    );
    expect(bottles.first.windowEnd, DateTime(2026, 9, 10, 9));
    expect(bottles[1].windowStart, DateTime(2026, 9, 10, 12, 30));
    expect(bottles.last.windowStart, DateTime(2026, 9, 11, 8, 30));
  });

  test('sans biberon : maintenant, puis 2 h 30 – 5 h plus tard', () {
    final now = DateTime(2026, 9, 10, 10);
    final bottles = project(
      plan: planFor(now: now),
      birthDate: birth,
      latestWeightGrams: 3600,
      now: now,
    );
    expect(bottles.first.windowStart, now);
    expect(bottles.first.windowEnd, now);
    expect(bottles[1].windowStart, DateTime(2026, 9, 10, 12, 30));
    expect(bottles[1].windowEnd, DateTime(2026, 9, 10, 15));
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
