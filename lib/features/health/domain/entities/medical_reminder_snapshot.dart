import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'medical_reminder_snapshot.freezed.dart';

/// Étape à rappeler par le digest du matin.
@freezed
abstract class MedicalReminderStage with _$MedicalReminderStage {
  const factory MedicalReminderStage({
    required MedicalStageId stageId,
    required DateTime dueFrom,
    required DateTime dueUntil,
    required bool hasAppointment,
  }) = _MedicalReminderStage;
}

/// Prochaines étapes non faites, écrites dans le foyer pour la Cloud Function.
@freezed
abstract class MedicalReminderSnapshot with _$MedicalReminderSnapshot {
  const factory MedicalReminderSnapshot({
    required List<MedicalReminderStage> stages,
    required DateTime computedAt,
  }) = _MedicalReminderSnapshot;
}
