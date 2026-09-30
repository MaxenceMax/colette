import 'dart:math';

import 'package:colette/features/photo_sharing/domain/use_cases/photo_reminder_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tire toujours la même minute dans la plage.
class _FixedMinute implements Random {
  const _FixedMinute(this.minute);

  final int minute;

  @override
  int nextInt(int max) => minute;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

void main() {
  final morning = DateTime(2026, 9, 30, 7);

  test('14 dates, une par jour, dans [8:00, 21:00[', () {
    final dates = planPhotoReminders(now: morning, lastSentAt: null);
    expect(dates, hasLength(photoReminderDays));
    for (var i = 0; i < dates.length; i++) {
      final day = DateTime(2026, 9, 30 + i);
      expect(DateTime(dates[i].year, dates[i].month, dates[i].day), day);
      expect(dates[i].hour, inInclusiveRange(8, 20));
    }
    expect(dates.last.month, 10);
    expect(dates.last.day, 13);
  });

  test('même jour → même heure, quelle que soit l\'heure du calcul', () {
    final early = planPhotoReminders(now: morning, lastSentAt: null);
    final later = planPhotoReminders(
      now: DateTime(2026, 9, 30, 7, 45),
      lastSentAt: null,
    );
    expect(later, early);
  });

  test('envoi fait aujourd\'hui : le jour courant est retiré', () {
    final dates = planPhotoReminders(
      now: morning,
      lastSentAt: DateTime(2026, 9, 30, 6, 30),
    );
    expect(dates, hasLength(photoReminderDays - 1));
    expect(dates.first.day, 1);
    expect(dates.first.month, 10);
  });

  test('envoi fait hier : le jour courant reste', () {
    final dates = planPhotoReminders(
      now: morning,
      lastSentAt: DateTime(2026, 9, 29, 20),
    );
    expect(dates.first.day, 30);
  });

  test('heure du jour déjà passée : retirée', () {
    final dates = planPhotoReminders(
      now: DateTime(2026, 9, 30, 10),
      lastSentAt: null,
      randomForDay: (_) => const _FixedMinute(60),
    );
    expect(dates, hasLength(photoReminderDays - 1));
    expect(dates.first, DateTime(2026, 10, 1, 9));
  });

  test('bornes de la plage', () {
    final first = planPhotoReminders(
      now: morning,
      lastSentAt: null,
      randomForDay: (_) => const _FixedMinute(0),
    ).first;
    final last = planPhotoReminders(
      now: morning,
      lastSentAt: null,
      randomForDay: (_) => const _FixedMinute(12 * 60 + 59),
    ).first;
    expect(first, DateTime(2026, 9, 30, 8));
    expect(last, DateTime(2026, 9, 30, 20, 59));
  });

  test('graine = aaaammjj', () {
    final seeds = <int>[];
    planPhotoReminders(
      now: morning,
      lastSentAt: null,
      randomForDay: (seed) {
        seeds.add(seed);
        return const _FixedMinute(0);
      },
    );
    expect(seeds.take(2), [20260930, 20261001]);
  });
}
