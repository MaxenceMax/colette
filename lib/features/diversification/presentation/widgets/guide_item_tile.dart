import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Repère sourcé, présenté en puce.
class GuideItemTile extends StatelessWidget {
  const GuideItemTile({super.key, required this.item});

  final GuideItem item;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return Padding(
      padding: AppSpacing.xs.vertical,
      child: Row(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Padding(
            padding: AppSpacing.sm.top,
            child: Icon(
              Icons.circle,
              size: AppSize.nano.value,
              color: secondary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(item.text, style: styles.body),
                Text(
                  s.ruleSources(sourcesLabel(item.sources, s)),
                  style: styles.small.copyWith(color: secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
