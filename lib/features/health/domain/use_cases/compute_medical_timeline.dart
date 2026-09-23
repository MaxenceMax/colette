import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/reference/medical_schedule.dart';
import 'package:colette/features/health/domain/use_cases/compute_custom_appointment_status.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_stage_status.dart';

/// Date et statut de chaque étape du calendrier et de chaque RDV libre.
class ComputeMedicalTimeline {
  const ComputeMedicalTimeline();

  MedicalTimeline call({
    required DateTime birthDate,
    required List<MedicalVisit> visits,
    List<CustomAppointment> appointments = const [],
    required DateTime now,
    List<MedicalStage> schedule = medicalSchedule,
  }) {
    final byStage = {for (final visit in visits) visit.stageId: visit};
    return MedicalTimeline(
      entries: [
        for (final stage in schedule)
          MedicalTimelineEntry(
            stage: stage,
            dueFrom: stage.from.from(birthDate),
            dueUntil: stage.until.from(birthDate),
            status: const ComputeMedicalStageStatus()(
              stage: stage,
              visit: byStage[stage.id],
              birthDate: birthDate,
              now: now,
            ),
            visit: byStage[stage.id],
          ),
      ],
      appointments: [
        for (final appointment in appointments)
          AppointmentItem(
            appointment,
            const ComputeCustomAppointmentStatus()(
              appointment: appointment,
              now: now,
            ),
          ),
      ],
    );
  }
}
