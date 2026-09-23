import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';

/// Statut d'une étape à [now] : faite, RDV passé, programmée, en retard, à faire, à venir.
class ComputeMedicalStageStatus {
  const ComputeMedicalStageStatus();

  /// Une étape passe « à faire » ce nombre de jours avant le début de sa fenêtre.
  static const reminderLeadDays = 14;

  MedicalStageStatus call({
    required MedicalStage stage,
    required MedicalVisit? visit,
    required DateTime birthDate,
    required DateTime now,
  }) {
    if (visit?.doneAt != null) return MedicalStageStatus.done;
    if (visit?.appointmentAt case final appointmentAt?) {
      return appointmentAt.isBefore(now)
          ? MedicalStageStatus.appointmentPassed
          : MedicalStageStatus.scheduled;
    }
    if (!now.isBefore(stage.until.from(birthDate))) {
      return MedicalStageStatus.late;
    }
    final dueFrom = stage.from.from(birthDate);
    final remindFrom = DateTime(
      dueFrom.year,
      dueFrom.month,
      dueFrom.day - reminderLeadDays,
    );
    return now.isBefore(remindFrom)
        ? MedicalStageStatus.upcoming
        : MedicalStageStatus.due;
  }
}
