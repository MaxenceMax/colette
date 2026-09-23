import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/health_status_text.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Ligne d'un RDV libre : titre, pastilles « RDV libre » / « Vaccins », statut.
class CustomAppointmentTile extends StatelessWidget {
  const CustomAppointmentTile({super.key, required this.item, this.onTap});

  final AppointmentItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return ListTile(
      contentPadding: AppSpacing.sm.horizontal,
      onTap: onTap,
      title: Text(item.appointment.title, style: styles.bodyMedium),
      subtitle: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.xxs.value,
        children: [
          Wrap(
            spacing: AppSpacing.xs.value,
            children: [
              MedicalChip(label: s.healthChipCustom),
              if (item.appointment.vaccines.isNotEmpty)
                MedicalChip(label: s.healthChipVaccines),
            ],
          ),
          Text(
            healthAppointmentStatusText(s, item),
            style: styles.small.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: context.appColor(AppColors.textSecondary),
      ),
    );
  }
}
