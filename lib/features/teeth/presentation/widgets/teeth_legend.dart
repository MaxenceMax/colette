import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Légende du schéma : sortie, tombée, pas encore.
class TeethLegend extends StatelessWidget {
  const TeethLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Wrap(
      alignment: .center,
      spacing: AppSpacing.md.value,
      runSpacing: AppSpacing.xs.value,
      children: [
        _LegendItem(
          label: s.teethLegendErupted,
          fill: AppColors.primary,
          border: AppColors.primary,
        ),
        _LegendItem(
          label: s.teethLegendLost,
          fill: AppColors.surfaceContainer,
          border: AppColors.border,
        ),
        _LegendItem(
          label: s.teethLegendAbsent,
          fill: AppColors.transparent,
          border: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.fill,
    required this.border,
  });

  final String label;
  final AppColors fill;
  final AppColors border;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    spacing: AppSpacing.xs.value,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          shape: .circle,
          color: context.appColor(fill),
          border: Border.all(
            color: context.appColor(border),
            width: AppSpacing.xxs.value,
          ),
        ),
        child: AppSize.xs.square,
      ),
      Text(label, style: Theme.of(context).coletteTextStyles.small),
    ],
  );
}
