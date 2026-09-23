import 'package:colette/features/sleep/domain/entities/sleep_status.dart';
import 'package:colette/features/sleep/domain/use_cases/compute_sleep_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 16);

  test('aucun sommeil : éveillé·e sans date, total nul', () {
    final summary = computeSleepSummary(
      recent: const [],
      latest: null,
      now: now,
    );
    expect(summary.status, const SleepStatus.awake());
    expect(summary.last24h, Duration.zero);
  });

  test('sommeil en cours : endormi·e, compté jusqu\'à maintenant', () {
    final ongoing = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 15, 18));
    final summary = computeSleepSummary(
      recent: [ongoing],
      latest: ongoing,
      now: now,
    );
    expect(summary.status, SleepStatus.asleep(ongoing));
    expect(summary.last24h, const Duration(minutes: 42));
  });

  test('éveillé·e depuis la fin du dernier sommeil terminé', () {
    final a = makeSleep(
      id: 'a',
      startAt: DateTime(2026, 9, 23, 13),
      endAt: DateTime(2026, 9, 23, 14, 50),
    );
    final summary = computeSleepSummary(recent: [a], latest: a, now: now);
    expect(
      summary.status,
      SleepStatus.awake(since: DateTime(2026, 9, 23, 14, 50)),
    );
  });

  test('un sommeil à cheval sur la fenêtre ne compte que sa partie dedans', () {
    final night = makeSleep(
      id: 'n',
      startAt: DateTime(2026, 9, 22, 14),
      endAt: DateTime(2026, 9, 22, 18),
    );
    final summary = computeSleepSummary(
      recent: [night],
      latest: night,
      now: now,
    );
    expect(summary.last24h, const Duration(hours: 2));
  });

  test('au-delà de 16 h, le sommeil en cours devient un réveil oublié', () {
    final old = makeSleep(id: 'o', startAt: DateTime(2026, 9, 22, 23, 59));
    final summary = computeSleepSummary(recent: [old], latest: old, now: now);
    expect(summary.status, SleepStatus.forgottenWake(old));
  });

  test('deux sommeils ouverts : le plus ancien fait foi', () {
    final first = makeSleep(id: 'a', startAt: DateTime(2026, 9, 23, 15));
    final dup = makeSleep(id: 'b', startAt: DateTime(2026, 9, 23, 15, 1));
    final summary = computeSleepSummary(
      recent: [dup, first],
      latest: dup,
      now: now,
    );
    expect(summary.status, SleepStatus.asleep(first));
    expect(summary.last24h, const Duration(minutes: 60));
  });

  test('le dernier sommeil hors fenêtre sert à « éveillé·e depuis »', () {
    final old = makeSleep(
      id: 'x',
      startAt: DateTime(2026, 9, 20, 10),
      endAt: DateTime(2026, 9, 20, 11),
    );
    final summary = computeSleepSummary(
      recent: const [],
      latest: old,
      now: now,
    );
    expect(summary.status, SleepStatus.awake(since: DateTime(2026, 9, 20, 11)));
    expect(summary.last24h, Duration.zero);
  });
}
