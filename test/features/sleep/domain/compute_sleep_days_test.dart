import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/domain/use_cases/compute_sleep_days.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sleep_session_factory.dart';

void main() {
  final today = DateTime(2026, 9, 23);
  final now = DateTime(2026, 9, 23, 16);

  test('sept jours, du plus ancien à aujourd\'hui', () {
    final days = computeSleepDays(const [], today: today, now: now);
    expect(days.map((d) => d.day), [
      for (var i = 6; i >= 0; i--) DateTime(2026, 9, 23 - i),
    ]);
    expect(
      days.every((d) => d.total == Duration.zero && d.segments.isEmpty),
      isTrue,
    );
  });

  test('une nuit qui passe minuit est découpée sur deux jours', () {
    final night = makeSleep(
      id: 'n',
      kind: SleepKind.night,
      startAt: DateTime(2026, 9, 22, 22),
      endAt: DateTime(2026, 9, 23, 6),
    );
    final days = computeSleepDays([night], today: today, now: now);
    final yesterday = days[5];
    final todayDay = days[6];
    expect(yesterday.total, const Duration(hours: 2));
    expect(todayDay.total, const Duration(hours: 6));
    expect(todayDay.segments.single.start, DateTime(2026, 9, 23));
    expect(yesterday.longest, const Duration(hours: 8));
    expect(todayDay.longest, Duration.zero);
  });

  test(
    'siestes comptées au jour de début, sommeil en cours jusqu\'à maintenant',
    () {
      final nap1 = makeSleep(
        id: 'a',
        startAt: DateTime(2026, 9, 23, 9),
        endAt: DateTime(2026, 9, 23, 10, 30),
      );
      final nap2 = makeSleep(id: 'b', startAt: DateTime(2026, 9, 23, 15));
      final days = computeSleepDays([nap1, nap2], today: today, now: now);
      expect(days.last.napCount, 2);
      expect(days.last.total, const Duration(hours: 2, minutes: 30));
      expect(days.last.longest, const Duration(minutes: 90));
    },
  );

  test('moyenne des jours précédents ayant du sommeil, sans aujourd\'hui', () {
    final a = makeSleep(
      id: 'a',
      startAt: DateTime(2026, 9, 21, 9),
      endAt: DateTime(2026, 9, 21, 23),
    );
    final b = makeSleep(
      id: 'b',
      startAt: DateTime(2026, 9, 22, 9),
      endAt: DateTime(2026, 9, 22, 21),
    );
    final c = makeSleep(
      id: 'c',
      startAt: DateTime(2026, 9, 23, 9),
      endAt: DateTime(2026, 9, 23, 10),
    );
    final days = computeSleepDays([a, b, c], today: today, now: now);
    expect(averageOfPreviousDays(days), const Duration(hours: 13));
  });

  test('moyenne nulle sans jour précédent noté', () {
    final days = computeSleepDays(const [], today: today, now: now);
    expect(averageOfPreviousDays(days), isNull);
  });
}
