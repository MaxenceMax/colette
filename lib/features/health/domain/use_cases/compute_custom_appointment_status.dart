import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';

/// Statut d'un RDV libre à [now] : fait, RDV passé ou programmé. Jamais
/// « en retard », « à faire » ni « à venir » : pas de fenêtre d'âge.
class ComputeCustomAppointmentStatus {
  const ComputeCustomAppointmentStatus();

  MedicalStageStatus call({
    required CustomAppointment appointment,
    required DateTime now,
  }) {
    if (appointment.doneAt != null) return MedicalStageStatus.done;
    return appointment.appointmentAt.isBefore(now)
        ? MedicalStageStatus.appointmentPassed
        : MedicalStageStatus.scheduled;
  }
}
