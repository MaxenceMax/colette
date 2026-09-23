import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  final birth = DateTime(2026, 9, 1);
  final now = DateTime(2026, 10, 20);

  test('les 3 premières étapes non faites et sans RDV, avec leurs dates', () {
    final timeline = const ComputeMedicalTimeline()(
      birthDate: birth,
      visits: [
        makeVisit(MedicalStageId.day8, doneAt: DateTime(2026, 9, 4)),
        makeVisit(MedicalStageId.week2, doneAt: DateTime(2026, 9, 12)),
        makeVisit(MedicalStageId.m2, appointmentAt: DateTime(2026, 11, 3, 10)),
      ],
      now: now,
    );
    final snapshot = const ComputeMedicalReminderSnapshot()(
      timeline: timeline,
      now: now,
    );
    expect(snapshot.computedAt, now);
    expect(snapshot.stages.map((s) => s.stageId), [
      MedicalStageId.m1,
      MedicalStageId.m3,
      MedicalStageId.m4,
    ]);
    expect(snapshot.stages.every((s) => s.hasAppointment == false), isTrue);
    expect(snapshot.stages[1].dueFrom, DateTime(2026, 12, 1));
    expect(snapshot.stages[1].dueUntil, DateTime(2027, 1, 1));
  });

  test('commence à la première étape sans RDV même si des étapes antérieures en ont un', () {
    final timeline = const ComputeMedicalTimeline()(
      birthDate: birth,
      visits: [
        makeVisit(MedicalStageId.day8, doneAt: DateTime(2026, 9, 4)),
        makeVisit(MedicalStageId.week2, doneAt: DateTime(2026, 9, 12)),
        makeVisit(MedicalStageId.m1, appointmentAt: DateTime(2026, 10, 5, 10)),
        makeVisit(MedicalStageId.m2, appointmentAt: DateTime(2026, 11, 3, 10)),
        makeVisit(MedicalStageId.m3, appointmentAt: DateTime(2026, 12, 3, 10)),
      ],
      now: now,
    );
    final snapshot = const ComputeMedicalReminderSnapshot()(
      timeline: timeline,
      now: now,
    );
    expect(snapshot.stages.first.stageId, MedicalStageId.m4);
  });
}
