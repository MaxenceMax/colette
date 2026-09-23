import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/widgets/weight_chart.dart';
import 'package:colette/features/baby/presentation/widgets/weight_trend_summary.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte « Poids » : dernière pesée, évolution et mini-courbe ; ouvre la courbe.
class WeightCard extends ConsumerWidget {
  const WeightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final weights = ref.watch(weightsProvider).value ?? const <WeightEntry>[];
    final trend = ref.watch(weightTrendProvider);
    final secondary = context.appColor(AppColors.textSecondary);
    return ColetteCardSurface(
      onTap: () => context.push(AppRoutes.weights),
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.weightCardTitle,
                  style: styles.overline.copyWith(
                    color: context.appColor(AppColors.primary),
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: secondary),
            ],
          ),
          switch (trend) {
            null => Text(
              s.weightCardEmpty,
              style: styles.body.copyWith(color: secondary),
            ),
            final trend => Row(
              crossAxisAlignment: .end,
              spacing: AppSpacing.md.value,
              children: [
                Expanded(flex: 3, child: WeightTrendSummary(trend: trend)),
                if (weights.length > 1)
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: AppSize.xxxl.value,
                      child: WeightChart(weights: weights, compact: true),
                    ),
                  ),
              ],
            ),
          },
        ],
      ),
    );
  }
}
