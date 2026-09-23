import 'package:colette/core/dates/time_format.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/l10n/generated/app_localizations.dart';

/// Phrase de statut d'une étape : fenêtre, RDV, retard, date de visite.
///
/// Si le statut et la visite sont incohérents (ex. `done` sans `doneAt`), se
/// rabat sur le texte de fenêtre plutôt que de planter.
String healthStatusText(S s, MedicalTimelineEntry entry) {
  final visit = entry.visit;
  final lastDay = DateTime(
    entry.dueUntil.year,
    entry.dueUntil.month,
    entry.dueUntil.day - 1,
  );
  final fallback = s.healthDueWindow(
    formatShortDate(entry.dueFrom),
    formatShortDate(lastDay),
  );
  return switch (entry.status) {
    MedicalStageStatus.done => switch (visit?.doneAt) {
      final doneAt? => s.healthDoneOn(formatShortDate(doneAt)),
      null => fallback,
    },
    MedicalStageStatus.appointmentPassed => switch (visit?.appointmentAt) {
      final appointmentAt? => s.healthAppointmentPassed(
        formatShortDate(appointmentAt),
      ),
      null => fallback,
    },
    MedicalStageStatus.scheduled => switch (visit?.appointmentAt) {
      final appointmentAt? => switch (visit?.practitioner) {
        final name? when name.trim().isNotEmpty => s.healthScheduledWith(
          formatDayAndTime(appointmentAt),
          name,
        ),
        _ => s.healthScheduled(formatDayAndTime(appointmentAt)),
      },
      null => fallback,
    },
    MedicalStageStatus.late => s.healthLateSince(
      formatShortDate(entry.dueUntil),
    ),
    MedicalStageStatus.due || MedicalStageStatus.upcoming => fallback,
  };
}
