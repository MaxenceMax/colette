import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/labels/health_labels.dart';
import 'package:colette/features/health/presentation/widgets/health_status_text.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Ligne d'une étape : libellé, pastilles, statut ; [onTap] ouvre la feuille.
class MedicalStageTile extends StatelessWidget {
  const MedicalStageTile({super.key, required this.entry, this.onTap});

  final MedicalTimelineEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final stage = entry.stage;
    final late = entry.status == MedicalStageStatus.late;
    return ListTile(
      contentPadding: AppSpacing.sm.horizontal,
      onTap: onTap,
      title: Text(HealthLabels.stage(s, stage.id), style: styles.bodyMedium),
      subtitle: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.xxs.value,
        children: [
          Wrap(
            spacing: AppSpacing.xs.value,
            children: [
              if (stage.hasExam) _Chip(label: s.healthChipExam),
              if (stage.hasVaccines) _Chip(label: s.healthChipVaccines),
              if (stage.hasCertificate) _Chip(label: s.healthChipCertificate),
            ],
          ),
          Text(
            healthStatusText(s, entry),
            style: styles.small.copyWith(
              color: context.appColor(
                late ? AppColors.warning : AppColors.textSecondary,
              ),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: AppSpacing.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xxs,
    ),
    decoration: BoxDecoration(
      color: context.appColor(AppColors.surfaceContainer),
      borderRadius: AppRadius.sm.circular,
    ),
    child: Text(label, style: Theme.of(context).coletteTextStyles.small),
  );
}
