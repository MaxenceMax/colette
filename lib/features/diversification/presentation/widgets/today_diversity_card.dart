import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/add_tasting_button.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Diversité du jour : groupes OMS couverts par les dégustations.
class TodayDiversityCard extends ConsumerWidget {
  const TodayDiversityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final diversity = ref.watch(dailyDiversityProvider);
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.todayDiversityTitle, style: styles.heading3),
              ),
              Text(
                s.todayDiversityTastings(diversity.tastingCount),
                style: styles.small.copyWith(color: secondary),
              ),
            ],
          ),
          Text(
            s.todayDiversityGroups(diversity.coveredGroups.length),
            style: styles.heading2,
          ),
          Wrap(
            spacing: AppSpacing.xs.value,
            runSpacing: AppSpacing.xs.value,
            children: [
              for (final group in FoodGroup.diversityGroups)
                _GroupChip(
                  label: group.shortLabel(s),
                  covered: diversity.coveredGroups.contains(group),
                ),
            ],
          ),
          Text(
            s.todayDiversityReference,
            style: styles.small.copyWith(color: secondary),
          ),
          const AddTastingButton(),
        ],
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({required this.label, required this.covered});

  final String label;
  final bool covered;

  @override
  Widget build(BuildContext context) {
    final color = context.appColor(
      covered ? AppColors.success : AppColors.textSecondary,
    );
    return Container(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: covered ? context.appColor(AppColors.primaryContainer) : null,
        border: Border.all(color: context.appColor(AppColors.border)),
        borderRadius: AppRadius.round.circular,
      ),
      child: Row(
        mainAxisSize: .min,
        spacing: AppSpacing.xxs.value,
        children: [
          if (covered) Icon(Icons.check, size: AppSize.xs.value, color: color),
          Text(
            label,
            style: Theme.of(context).coletteTextStyles.small
                .copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
