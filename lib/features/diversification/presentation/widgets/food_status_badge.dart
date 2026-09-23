import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Statut d'un aliment : texte coloré et icône de précaution éventuelle.
class FoodStatusBadge extends StatelessWidget {
  const FoodStatusBadge({super.key, required this.status});

  final FoodStatus status;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (label, color) = switch (status) {
      FoodStatusAvoid(:final untilMonths, :final sources) => (
        s.statusAvoid(ageLimitLabel(untilMonths, s), sourcesLabel(sources, s)),
        AppColors.error,
      ),
      FoodStatusNotYetRecommended() => (
        s.statusNotYet,
        AppColors.textSecondary,
      ),
      FoodStatusTasted(:final count) => (
        s.statusTasted(count),
        AppColors.success,
      ),
      FoodStatusNotTasted() => (s.statusNotTasted, AppColors.textSecondary),
    };
    final needsPreparation = switch (status) {
      FoodStatusTasted(:final needsPreparation) ||
      FoodStatusNotTasted(:final needsPreparation) => needsPreparation,
      _ => false,
    };
    return Row(
      mainAxisSize: .min,
      spacing: AppSpacing.xs.value,
      children: [
        if (needsPreparation)
          Icon(
            Icons.content_cut,
            size: AppSize.xs.value,
            color: context.appColor(AppColors.warning),
            semanticLabel: s.statusPrepare,
          ),
        Flexible(
          child: Text(
            label,
            textAlign: .end,
            style: Theme.of(context).coletteTextStyles.small
                .copyWith(color: context.appColor(color)),
          ),
        ),
      ],
    );
  }
}
