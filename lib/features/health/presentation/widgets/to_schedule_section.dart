import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/labels/health_labels.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';

/// Section « À programmer » : étapes en retard puis à faire, en lignes
/// compactes et discrètes, sans carte ni pastilles. Rien si vide.
class ToScheduleSection extends StatelessWidget {
  const ToScheduleSection({super.key, required this.items});

  final List<MedicalTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    final entries = [
      for (final item in items)
        if (item case StageItem(:final entry)) entry,
    ];
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(title: S.of(context).healthSectionToSchedule),
        for (final (index, entry) in entries.indexed) ...[
          if (index > 0)
            Divider(
              height: AppSpacing.none.value,
              color: context.appColor(AppColors.border),
            ),
          CompactStageRow(
            entry: entry,
            onTap: () => showMedicalStageSheet(context, entry),
          ),
        ],
      ],
    );
  }
}

/// Ligne compacte d'une étape à caler : libellé à gauche, « en retard » ou
/// fenêtre courte à droite.
class CompactStageRow extends StatelessWidget {
  const CompactStageRow({super.key, required this.entry, this.onTap});

  final MedicalTimelineEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final late = entry.status == MedicalStageStatus.late;
    final lastDay = DateTime(
      entry.dueUntil.year,
      entry.dueUntil.month,
      entry.dueUntil.day - 1,
    );
    final trailing = late
        ? s.healthLateShort
        : s.healthDueWindowShort(
            formatDayMonth(entry.dueFrom),
            formatDayMonth(lastDay),
          );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: AppSpacing.sm.all,
        child: Row(
          spacing: AppSpacing.sm.value,
          children: [
            Expanded(
              child: Text(
                HealthLabels.stage(s, entry.stage.id),
                style: styles.body.copyWith(color: secondary),
              ),
            ),
            Text(
              trailing,
              style: styles.small.copyWith(
                color: late ? context.appColor(AppColors.warning) : secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
