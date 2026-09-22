import 'package:colette/features/dashboard/domain/entities/rolling_intake.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_rolling_intake.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  const compute = ComputeRollingIntake();
  final now = DateTime(2026, 9, 22, 10, 30);

  test('liste vide : zéro biberon, zéro ml', () {
    expect(
      compute(events: const [], now: now),
      const RollingIntake(bottles: 0, ml: 0),
    );
  });

  test('somme les biberons des dernières 24 h', () {
    final events = [
      makeEvent(id: 'a', startAt: DateTime(2026, 9, 22, 8), bottleMl: 90),
      makeEvent(id: 'b', startAt: DateTime(2026, 9, 21, 23, 50), bottleMl: 60),
    ];
    expect(
      compute(events: events, now: now),
      const RollingIntake(bottles: 2, ml: 150),
    );
  });

  test('un biberon à exactement 24 h est retenu', () {
    final events = [
      makeEvent(startAt: DateTime(2026, 9, 21, 10, 30), bottleMl: 70),
    ];
    expect(
      compute(events: events, now: now),
      const RollingIntake(bottles: 1, ml: 70),
    );
  });

  test('un biberon à plus de 24 h est exclu', () {
    final events = [
      makeEvent(startAt: DateTime(2026, 9, 21, 10, 29), bottleMl: 70),
    ];
    expect(
      compute(events: events, now: now),
      const RollingIntake(bottles: 0, ml: 0),
    );
  });

  test('un biberon dans le futur est exclu', () {
    final events = [
      makeEvent(startAt: DateTime(2026, 9, 22, 10, 31), bottleMl: 70),
    ];
    expect(
      compute(events: events, now: now),
      const RollingIntake(bottles: 0, ml: 0),
    );
  });

  test('les événements sans biberon sont ignorés', () {
    final events = [
      makeEvent(id: 'a', startAt: DateTime(2026, 9, 22, 9), diaperChange: true),
      makeEvent(id: 'b', startAt: DateTime(2026, 9, 22, 8), bottleMl: 90),
    ];
    expect(
      compute(events: events, now: now),
      const RollingIntake(bottles: 1, ml: 90),
    );
  });
}
