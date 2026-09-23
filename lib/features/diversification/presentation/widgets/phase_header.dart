import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/age_guide_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Titre de l'onglet, phase OMS et repas conseillés, accès aux repères.
class PhaseHeader extends ConsumerWidget {
  const PhaseHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final phase = ref.watch(diversificationTimelineProvider)?.phase;
    final guide = ref.watch(foodCatalogProvider).value?.guide;
    final meals = phase == null ? null : guide?.phases[phase]?.mealsSummary;
    final subtitle = switch ((phase, meals)) {
      (final phase?, final meals?) => s.plateSubtitle(phase.label(s), meals),
      (final phase?, null) => phase.label(s),
      _ => s.plateNoProfile,
    };
    return Row(
      crossAxisAlignment: .start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            spacing: AppSpacing.xxs.value,
            children: [
              Text(s.plateTitle, style: styles.heading1),
              Text(
                subtitle,
                style: styles.body.copyWith(
                  color: context.appColor(AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: s.plateGuideTooltip,
          icon: const Icon(Icons.info_outline),
          onPressed: guide == null
              ? null
              : () => showAgeGuideSheet(
                  context,
                  phase: phase ?? DiversificationPhase.preparation,
                ),
        ),
      ],
    );
  }
}
