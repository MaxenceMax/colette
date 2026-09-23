import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/health/domain/entities/medical_reminder_snapshot.dart';

/// Conversion du snapshot vers le champ `medicalReminder` du foyer.
abstract final class MedicalReminderSnapshotDto {
  static Map<String, dynamic> toMap(MedicalReminderSnapshot snapshot) => {
    'stages': [
      for (final stage in snapshot.stages)
        {
          'stageId': stage.stageId.name,
          'dueFrom': Timestamp.fromDate(stage.dueFrom),
          'dueUntil': Timestamp.fromDate(stage.dueUntil),
          'hasAppointment': stage.hasAppointment,
        },
    ],
    'computedAt': Timestamp.fromDate(snapshot.computedAt),
  };
}
