import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  final birth = DateTime(2026, 9, 1);
  final now = DateTime(2026, 10, 20);

  test('les 3 premières étapes non faites, avec leurs dates et le RDV', () {
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
      MedicalStageId.m2,
      MedicalStageId.m3,
    ]);
    expect(snapshot.stages[0].hasAppointment, isFalse);
    expect(snapshot.stages[1].hasAppointment, isTrue);
    expect(snapshot.stages[2].dueFrom, DateTime(2026, 12, 1));
    expect(snapshot.stages[2].dueUntil, DateTime(2027, 1, 1));
  });
}
