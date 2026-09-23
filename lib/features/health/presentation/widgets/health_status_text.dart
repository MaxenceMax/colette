import 'package:colette/core/dates/time_format.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/l10n/generated/app_localizations.dart';

/// Phrase de statut d'une étape : fenêtre, RDV, retard, date de visite.
String healthStatusText(S s, MedicalTimelineEntry entry) {
  final visit = entry.visit;
  final lastDay = DateTime(
    entry.dueUntil.year,
    entry.dueUntil.month,
    entry.dueUntil.day - 1,
  );
  return switch (entry.status) {
    MedicalStageStatus.done => s.healthDoneOn(formatShortDate(visit!.doneAt!)),
    MedicalStageStatus.appointmentPassed => s.healthAppointmentPassed(
      formatShortDate(visit!.appointmentAt!),
    ),
    MedicalStageStatus.scheduled => switch (visit!.practitioner) {
      final name? when name.trim().isNotEmpty => s.healthScheduledWith(
        formatDayAndTime(visit.appointmentAt!),
        name,
      ),
      _ => s.healthScheduled(formatDayAndTime(visit.appointmentAt!)),
    },
    MedicalStageStatus.late => s.healthLateSince(
      formatShortDate(entry.dueUntil),
    ),
    MedicalStageStatus.due || MedicalStageStatus.upcoming => s.healthDueWindow(
      formatShortDate(entry.dueFrom),
      formatShortDate(lastDay),
    ),
  };
}
