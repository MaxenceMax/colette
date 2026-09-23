import 'package:colette/features/health/domain/entities/medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';

/// Les [count] premières étapes non faites de la frise.
class ComputeMedicalReminderSnapshot {
  const ComputeMedicalReminderSnapshot();

  static const count = 3;

  MedicalReminderSnapshot call({
    required MedicalTimeline timeline,
    required DateTime now,
  }) => MedicalReminderSnapshot(
    stages: [
      for (final entry
          in timeline.entries
              .where((e) => e.status != MedicalStageStatus.done)
              .take(count))
        MedicalReminderStage(
          stageId: entry.stage.id,
          dueFrom: entry.dueFrom,
          dueUntil: entry.dueUntil,
          hasAppointment: entry.visit?.appointmentAt != null,
        ),
    ],
    computedAt: now,
  );
}
