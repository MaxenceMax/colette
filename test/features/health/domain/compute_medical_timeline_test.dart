import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  const compute = ComputeMedicalTimeline();
  final birth = DateTime(2026, 9, 1);

  test('une entrée par étape, avec dates absolues et visite', () {
    final visit = makeVisit(MedicalStageId.day8, doneAt: DateTime(2026, 9, 4));
    final timeline = compute(
      birthDate: birth,
      visits: [visit],
      now: DateTime(2026, 9, 10),
    );
    expect(timeline.entries, hasLength(MedicalStageId.values.length));
    final day8 = timeline.entries.first;
    expect(day8.stage.id, MedicalStageId.day8);
    expect(day8.visit, visit);
    expect(day8.status, MedicalStageStatus.done);
    final week2 = timeline.entries[1];
    expect(week2.dueFrom, DateTime(2026, 9, 9));
    expect(week2.dueUntil, DateTime(2026, 9, 16));
    expect(week2.status, MedicalStageStatus.due);
  });

  test('next : première étape non faite', () {
    final timeline = compute(
      birthDate: birth,
      visits: [
        makeVisit(MedicalStageId.day8, doneAt: DateTime(2026, 9, 4)),
        makeVisit(MedicalStageId.week2, doneAt: DateTime(2026, 9, 12)),
      ],
      now: DateTime(2026, 9, 20),
    );
    expect(timeline.next!.stage.id, MedicalStageId.m1);
    expect(timeline.next!.status, MedicalStageStatus.due);
  });

  test('next : null quand tout est fait', () {
    final timeline = compute(
      birthDate: birth,
      visits: [
        for (final id in MedicalStageId.values)
          makeVisit(id, doneAt: DateTime(2026, 9, 2)),
      ],
      now: DateTime(2030),
    );
    expect(timeline.next, isNull);
  });
}
