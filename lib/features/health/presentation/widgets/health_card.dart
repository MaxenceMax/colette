import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/labels/health_labels.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/widgets/health_status_text.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte « Santé » d'Aujourd'hui : prochaine étape du suivi médical.
class HealthCard extends ConsumerWidget {
  const HealthCard({super.key});

  /// Au-delà, une étape à venir s'affiche en une ligne discrète.
  static const farDays = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(medicalTimelineProvider);
    if (timeline == null) return const SizedBox.shrink();
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final next = timeline.next;
    final today = ref.watch(todayProvider);
    return ColetteCardSurface(
      onTap: () => context.push(AppRoutes.health),
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          Icon(
            Icons.medical_services_outlined,
            color: context.appColor(AppColors.primary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: AppSpacing.xxs.value,
              children: [
                Text(s.healthTitle, style: styles.bodyMedium),
                ..._lines(context, s, next, today),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: secondary),
        ],
      ),
    );
  }

  List<Widget> _lines(
    BuildContext context,
    S s,
    MedicalTimelineEntry? next,
    DateTime today,
  ) {
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = styles.small.copyWith(
      color: context.appColor(AppColors.textSecondary),
    );
    if (next == null) return [Text(s.healthAllDone, style: secondary)];
    final label = HealthLabels.stage(s, next.stage.id);
    final far =
        next.status == MedicalStageStatus.upcoming &&
        calendarDaysBetween(today, next.dueFrom) > farDays;
    if (far) {
      return [
        Text(
          s.healthNextFar(label, formatShortDate(next.dueFrom)),
          style: secondary,
        ),
      ];
    }
    final late = next.status == MedicalStageStatus.late;
    return [
      Text(label, style: styles.body),
      Text(
        healthStatusText(s, next),
        style: late
            ? styles.small.copyWith(color: context.appColor(AppColors.warning))
            : secondary,
      ),
    ];
  }
}
