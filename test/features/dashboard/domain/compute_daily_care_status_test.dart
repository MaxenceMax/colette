import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_daily_care_status.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  const compute = ComputeDailyCareStatus();
  final now = DateTime(2026, 9, 21, 14);
  const everyTwoDays = CareSettings(adrigyl: CareFrequency(everyDays: 2));

  test('réglages par défaut sans événement : 5 tâches, aucune faite', () {
    final tasks = compute(
      settings: const CareSettings(),
      events: const [],
      now: now,
    );
    expect(tasks.map((t) => t.type), [
      CareType.adrigyl,
      CareType.eyeCare,
      CareType.noseCare,
      CareType.umbilicalCare,
      CareType.bath,
    ]);
    expect(tasks.every((t) => !t.isDone), isTrue);
  });

  test('un Adrigyl aujourd\'hui marque la tâche faite avec son heure', () {
    final event = makeEvent(startAt: DateTime(2026, 9, 21, 8), adrigyl: true);
    final tasks = compute(
      settings: const CareSettings(),
      events: [event],
      now: now,
    );
    final adrigyl = tasks.firstWhere((t) => t.type == CareType.adrigyl);
    expect(adrigyl.isDone, isTrue);
    expect(adrigyl.lastDoneAt, event.startAt);
  });

  test('un Adrigyl d\'hier ne compte pas pour aujourd\'hui (1/jour)', () {
    final event = makeEvent(startAt: DateTime(2026, 9, 20, 8), adrigyl: true);
    final tasks = compute(
      settings: const CareSettings(),
      events: [event],
      now: now,
    );
    final adrigyl = tasks.firstWhere((t) => t.type == CareType.adrigyl);
    expect(adrigyl.isDone, isFalse);
    expect(adrigyl.lastDoneAt, isNull);
  });

  test('2/jour avec une prise reste à faire', () {
    final event = makeEvent(startAt: DateTime(2026, 9, 21, 8), adrigyl: true);
    final tasks = compute(
      settings: const CareSettings(adrigyl: CareFrequency(timesPerDay: 2)),
      events: [event],
      now: now,
    );
    final adrigyl = tasks.firstWhere((t) => t.type == CareType.adrigyl);
    expect(adrigyl.target, 2);
    expect(adrigyl.done, 1);
    expect(adrigyl.isDone, isFalse);
  });

  test('nombril 3 par jour par défaut : deux soins faits, reste à faire', () {
    final tasks = compute(
      settings: const CareSettings(),
      events: [
        makeEvent(
          id: 'u1',
          startAt: DateTime(2026, 9, 21, 8),
          umbilicalCare: true,
        ),
        makeEvent(
          id: 'u2',
          startAt: DateTime(2026, 9, 21, 12),
          umbilicalCare: true,
        ),
      ],
      now: now,
    );
    final umbilical = tasks.firstWhere((t) => t.type == CareType.umbilicalCare);
    expect(umbilical.target, 3);
    expect(umbilical.done, 2);
    expect(umbilical.isDone, isFalse);
    expect(umbilical.lastDoneAt, DateTime(2026, 9, 21, 12));
  });

  test('soin désactivé : absent, même fait aujourd\'hui', () {
    final tasks = compute(
      settings: const CareSettings(
        umbilicalCare: CareFrequency(timesPerDay: 3, enabled: false),
      ),
      events: [
        makeEvent(startAt: DateTime(2026, 9, 21, 8), umbilicalCare: true),
      ],
      now: now,
    );
    expect(tasks.any((t) => t.type == CareType.umbilicalCare), isFalse);
  });

  test('tous les 2 jours, fait hier : absent', () {
    final tasks = compute(
      settings: everyTwoDays,
      events: [makeEvent(startAt: DateTime(2026, 9, 20, 18), adrigyl: true)],
      now: now,
    );
    expect(tasks.any((t) => t.type == CareType.adrigyl), isFalse);
  });

  test('tous les 2 jours, fait avant-hier : listé, à faire', () {
    final tasks = compute(
      settings: everyTwoDays,
      events: [makeEvent(startAt: DateTime(2026, 9, 19, 18), adrigyl: true)],
      now: now,
    );
    final adrigyl = tasks.firstWhere((t) => t.type == CareType.adrigyl);
    expect(adrigyl.isDone, isFalse);
    expect(adrigyl.target, 1);
  });

  test('tous les 2 jours, jamais fait : listé, à faire', () {
    final tasks = compute(settings: everyTwoDays, events: const [], now: now);
    expect(tasks.any((t) => t.type == CareType.adrigyl && !t.isDone), isTrue);
  });

  test('tous les 2 jours, fait hier et aujourd\'hui : listé, fait', () {
    final today = makeEvent(
      id: 'a2',
      startAt: DateTime(2026, 9, 21, 9),
      adrigyl: true,
    );
    final tasks = compute(
      settings: everyTwoDays,
      events: [
        makeEvent(id: 'a1', startAt: DateTime(2026, 9, 20, 9), adrigyl: true),
        today,
      ],
      now: now,
    );
    final adrigyl = tasks.firstWhere((t) => t.type == CareType.adrigyl);
    expect(adrigyl.isDone, isTrue);
    expect(adrigyl.lastDoneAt, today.startAt);
  });

  test(
    'bain hier (tous les 2 jours par défaut) : pas attendu aujourd\'hui',
    () {
      final tasks = compute(
        settings: const CareSettings(),
        events: [makeEvent(startAt: DateTime(2026, 9, 20, 18), bath: true)],
        now: now,
      );
      expect(tasks.any((t) => t.type == CareType.bath), isFalse);
    },
  );

  test(
    'DST : bain de 2 jours civils reste attendu malgré le changement d\'heure',
    () {
      final tasks = compute(
        settings: const CareSettings(),
        events: [makeEvent(startAt: DateTime(2026, 3, 28, 20), bath: true)],
        now: DateTime(2026, 3, 30, 8),
      );
      expect(tasks.any((t) => t.type == CareType.bath && !t.isDone), isTrue);
    },
  );
}
