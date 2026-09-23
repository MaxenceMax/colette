import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/reference/medical_schedule.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_stage_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  const compute = ComputeMedicalStageStatus();
  final birth = DateTime(2026, 9, 1);
  final m2 = stageById(MedicalStageId.m2); // [1er nov., 1er déc.)

  MedicalStageStatus status(DateTime now, [MedicalVisit? visit]) =>
      compute(stage: m2, visit: visit, birthDate: birth, now: now);

  test('upcoming jusqu\'à 14 jours avant le début', () {
    expect(status(DateTime(2026, 10, 17, 23, 59)), MedicalStageStatus.upcoming);
  });

  test('due à partir de 14 jours avant le début et pendant la fenêtre', () {
    expect(status(DateTime(2026, 10, 18)), MedicalStageStatus.due);
    expect(status(DateTime(2026, 11, 30, 23)), MedicalStageStatus.due);
  });

  test('late dès la fin de la fenêtre', () {
    expect(status(DateTime(2026, 12, 1)), MedicalStageStatus.late);
  });

  test('scheduled avec un RDV futur, même en retard', () {
    final visit = makeVisit(
      MedicalStageId.m2,
      appointmentAt: DateTime(2026, 12, 3, 10),
    );
    expect(status(DateTime(2026, 12, 2), visit), MedicalStageStatus.scheduled);
  });

  test('appointmentPassed quand le RDV est passé sans visite marquée', () {
    final visit = makeVisit(
      MedicalStageId.m2,
      appointmentAt: DateTime(2026, 11, 3, 10),
    );
    expect(
      status(DateTime(2026, 11, 3, 10, 1), visit),
      MedicalStageStatus.appointmentPassed,
    );
  });

  test('done dès que la visite est marquée faite', () {
    final visit = makeVisit(
      MedicalStageId.m2,
      appointmentAt: DateTime(2026, 11, 3, 10),
      doneAt: DateTime(2026, 11, 3, 10),
    );
    expect(status(DateTime(2027), visit), MedicalStageStatus.done);
  });
}
