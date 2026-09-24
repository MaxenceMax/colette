import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/health/domain/entities/appointment_proximity.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/labels/health_labels.dart';
import 'package:colette/features/health/presentation/widgets/custom_appointment_sheet.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_sheet.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Libellé d'un élément : nom de l'étape ou titre du RDV libre.
String timelineItemTitle(S s, MedicalTimelineItem item) => switch (item) {
  StageItem(:final entry) => HealthLabels.stage(s, entry.stage.id),
  AppointmentItem(:final appointment) => appointment.title,
};

/// « Aujourd'hui à 10h30 », « Demain à 10h30 » ou « jeu. 2 oct., 10h30 ».
String appointmentDateText(
  S s,
  DateTime appointmentAt,
  AppointmentProximity proximity,
) => switch (proximity) {
  AppointmentProximity.today => s.healthTodayAt(
    formatHourMinute(appointmentAt),
  ),
  AppointmentProximity.tomorrow => s.healthTomorrowAt(
    formatHourMinute(appointmentAt),
  ),
  AppointmentProximity.soon ||
  AppointmentProximity.later => formatDayAndTime(appointmentAt),
};

/// Ouvre la feuille d'étape ou de RDV libre selon [item].
Future<void> showTimelineItemSheet(
  BuildContext context,
  MedicalTimelineItem item,
) => switch (item) {
  StageItem(:final entry) => showMedicalStageSheet(context, entry),
  AppointmentItem(:final appointment) => showCustomAppointmentSheet(
    context,
    initial: appointment,
  ),
};

/// Pastilles d'un élément : Examen / Vaccins / Certificat pour une étape,
/// RDV libre / Vaccins pour un RDV libre.
class TimelineItemChips extends StatelessWidget {
  const TimelineItemChips({
    super.key,
    required this.item,
    this.backgroundColor = AppColors.surfaceContainer,
  });

  final MedicalTimelineItem item;

  /// Couleur de fond des pastilles.
  final AppColors backgroundColor;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final labels = switch (item) {
      StageItem(:final entry) => [
        if (entry.stage.hasExam) s.healthChipExam,
        if (entry.stage.hasVaccines) s.healthChipVaccines,
        if (entry.stage.hasCertificate) s.healthChipCertificate,
      ],
      AppointmentItem(:final appointment) => [
        s.healthChipCustom,
        if (appointment.vaccines.isNotEmpty) s.healthChipVaccines,
      ],
    };
    return Wrap(
      spacing: AppSpacing.xs.value,
      children: [
        for (final label in labels)
          MedicalChip(label: label, backgroundColor: backgroundColor),
      ],
    );
  }
}
