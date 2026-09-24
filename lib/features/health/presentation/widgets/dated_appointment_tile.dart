import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/timeline_item_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Ligne d'un RDV programmé : bloc date à gauche, libellé, heure et
/// praticien (ou « RDV libre »), chevron ; [onTap] ouvre la feuille.
class DatedAppointmentTile extends StatelessWidget {
  const DatedAppointmentTile({
    super.key,
    required this.item,
    required this.appointmentAt,
    this.onTap,
  });

  final MedicalTimelineItem item;
  final DateTime appointmentAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final detail = switch (item) {
      StageItem() => item.practitioner,
      AppointmentItem() => item.practitioner ?? s.healthChipCustom,
    };
    return ListTile(
      contentPadding: AppSpacing.sm.horizontal,
      onTap: onTap,
      leading: Column(
        mainAxisSize: .min,
        mainAxisAlignment: .center,
        children: [
          Text(formatDayOfMonth(appointmentAt), style: styles.numberMedium),
          Text(
            formatShortMonth(appointmentAt),
            style: styles.small.copyWith(color: secondary),
          ),
        ],
      ),
      title: Text(timelineItemTitle(s, item), style: styles.bodyMedium),
      subtitle: Text(
        [formatHourMinute(appointmentAt), ?detail].join(' · '),
        style: styles.small.copyWith(color: secondary),
      ),
      trailing: Icon(Icons.chevron_right, color: secondary),
    );
  }
}
