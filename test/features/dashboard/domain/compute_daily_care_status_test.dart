import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_daily_care_status.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  const compute = ComputeDailyCareStatus();
  final now = DateTime(2026, 9, 21, 14);

  test('réglages par défaut sans événement : 5 tâches, aucune faite', () {
    final tasks = compute(
      settings: const CareSettings(),
      todayEvents: const [],
      lastBath: null,
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
      todayEvents: [event],
      lastBath: null,
      now: now,
    );
    final adrigyl = tasks.firstWhere((t) => t.type == CareType.adrigyl);
    expect(adrigyl.isDone, isTrue);
    expect(adrigyl.lastDoneAt, event.startAt);
  });

  test('adrigylPerDay 2 avec une prise reste à faire', () {
    final event = makeEvent(startAt: DateTime(2026, 9, 21, 8), adrigyl: true);
    final tasks = compute(
      settings: const CareSettings(adrigylPerDay: 2),
      todayEvents: [event],
      lastBath: null,
      now: now,
    );
    final adrigyl = tasks.firstWhere((t) => t.type == CareType.adrigyl);
    expect(adrigyl.target, 2);
    expect(adrigyl.done, 1);
    expect(adrigyl.isDone, isFalse);
  });

  test('nombril désactivé : pas de tâche nombril', () {
    final tasks = compute(
      settings: const CareSettings(umbilicalCareEnabled: false),
      todayEvents: const [],
      lastBath: null,
      now: now,
    );
    expect(tasks.any((t) => t.type == CareType.umbilicalCare), isFalse);
  });

  test('bain hier avec bathEveryDays 2 : pas attendu aujourd\'hui', () {
    final bath = makeEvent(startAt: DateTime(2026, 9, 20, 18), bath: true);
    final tasks = compute(
      settings: const CareSettings(),
      todayEvents: const [],
      lastBath: bath,
      now: now,
    );
    expect(tasks.any((t) => t.type == CareType.bath), isFalse);
  });

  test('bain avant-hier avec bathEveryDays 2 : attendu', () {
    final bath = makeEvent(startAt: DateTime(2026, 9, 19, 18), bath: true);
    final tasks = compute(
      settings: const CareSettings(),
      todayEvents: const [],
      lastBath: bath,
      now: now,
    );
    expect(tasks.any((t) => t.type == CareType.bath && !t.isDone), isTrue);
  });

  test(
    'DST : bain de 2 jours civils reste attendu malgré le changement d\'heure',
    () {
      // Passage à l'heure d'été le 29 mars 2026 entre le bain et maintenant.
      final bath = makeEvent(startAt: DateTime(2026, 3, 28, 20), bath: true);
      final tasks = compute(
        settings: const CareSettings(),
        todayEvents: const [],
        lastBath: bath,
        now: DateTime(2026, 3, 30, 8),
      );
      expect(tasks.any((t) => t.type == CareType.bath && !t.isDone), isTrue);
    },
  );

  test('bain aujourd\'hui : listé et fait', () {
    final bath = makeEvent(startAt: DateTime(2026, 9, 21, 9), bath: true);
    final tasks = compute(
      settings: const CareSettings(),
      todayEvents: [bath],
      lastBath: bath,
      now: now,
    );
    final task = tasks.firstWhere((t) => t.type == CareType.bath);
    expect(task.isDone, isTrue);
  });
}
