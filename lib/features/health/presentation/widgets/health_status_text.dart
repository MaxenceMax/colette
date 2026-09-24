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
  final fallback = s.healthDueWindow(
    formatShortDate(entry.dueFrom),
    formatShortDate(entry.lastDueDay),
  );
  return switch (entry.status) {
    MedicalStageStatus.done ||
    MedicalStageStatus.appointmentPassed ||
    MedicalStageStatus.scheduled =>
      _appointmentPhrase(
            s,
            entry.status,
            appointmentAt: visit?.appointmentAt,
            practitioner: visit?.practitioner,
            doneAt: visit?.doneAt,
          ) ??
          fallback,
    MedicalStageStatus.late => s.healthLateSince(
      formatShortDate(entry.dueUntil),
    ),
    MedicalStageStatus.due || MedicalStageStatus.upcoming => fallback,
  };
}

/// Phrase de statut d'un RDV libre : fait, RDV passé ou programmé.
String healthAppointmentStatusText(S s, AppointmentItem item) {
  final a = item.appointment;
  return _appointmentPhrase(
        s,
        item.status,
        appointmentAt: a.appointmentAt,
        practitioner: a.practitioner,
        doneAt: a.doneAt,
      ) ??
      s.healthScheduled(formatDayAndTime(a.appointmentAt));
}

/// `null` si les données ne permettent pas la phrase attendue par [status].
String? _appointmentPhrase(
  S s,
  MedicalStageStatus status, {
  required DateTime? appointmentAt,
  required String? practitioner,
  required DateTime? doneAt,
}) => switch (status) {
  MedicalStageStatus.done => switch (doneAt) {
    final doneAt? => s.healthDoneOn(formatShortDate(doneAt)),
    null => null,
  },
  MedicalStageStatus.appointmentPassed => switch (appointmentAt) {
    final at? => s.healthAppointmentPassed(formatShortDate(at)),
    null => null,
  },
  MedicalStageStatus.scheduled => switch (appointmentAt) {
    final at? => switch (practitioner) {
      final name? when name.trim().isNotEmpty => s.healthScheduledWith(
        formatDayAndTime(at),
        name,
      ),
      _ => s.healthScheduled(formatDayAndTime(at)),
    },
    null => null,
  },
  _ => null,
};
