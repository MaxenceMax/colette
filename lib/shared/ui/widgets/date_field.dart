import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

/// Champ non éditable « libellé / valeur » qui ouvre un sélecteur au tap.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    return Material(
      color: context.appColor(AppColors.surfaceContainer),
      borderRadius: AppRadius.md.circular,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.md.all,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: styles.label.copyWith(
                    color: context.appColor(AppColors.textSecondary),
                  ),
                ),
              ),
              Text(value, style: styles.bodyMedium),
              AppSpacing.xs.horizontalSpace,
              Icon(
                Icons.chevron_right,
                size: AppSize.xs.value,
                color: context.appColor(AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
