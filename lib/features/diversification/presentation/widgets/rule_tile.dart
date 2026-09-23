import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Règle d'un aliment : nature et âge limite, texte, sources.
class RuleTile extends StatelessWidget {
  const RuleTile({super.key, required this.rule});

  final FoodRule rule;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final until = ageLimitLabel(rule.untilMonths ?? 0, s);
    final (title, icon, color) = switch (rule.kind) {
      RuleKind.avoid => (s.ruleAvoidUntil(until), Icons.block, AppColors.error),
      RuleKind.prepare => (
        s.rulePrepareUntil(until),
        Icons.content_cut,
        AppColors.warning,
      ),
      RuleKind.info => (
        s.ruleInfo,
        Icons.info_outline,
        AppColors.textSecondary,
      ),
    };
    return Padding(
      padding: AppSpacing.xs.vertical,
      child: Row(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Icon(icon, size: AppSize.sm.value, color: context.appColor(color)),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: AppSpacing.xxs.value,
              children: [
                Text(
                  title,
                  style: styles.label.copyWith(color: context.appColor(color)),
                ),
                Text(rule.text, style: styles.body),
                Text(
                  s.ruleSources(sourcesLabel(rule.sources, s)),
                  style: styles.small.copyWith(
                    color: context.appColor(AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
