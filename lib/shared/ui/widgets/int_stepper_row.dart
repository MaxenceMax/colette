import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Ligne « libellé … [-] valeur [+] » bornée par [min] et [max].
class IntStepperRow extends StatelessWidget {
  const IntStepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.suffix,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String? suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    return Row(
      children: [
        Expanded(child: Text(label, style: styles.body)),
        IconButton(
          onPressed: value - step >= min ? () => onChanged(value - step) : null,
          icon: const Icon(Icons.remove),
          color: context.appColor(AppColors.primary),
          tooltip: S.of(context).actionDecrease,
        ),
        Text(
          suffix == null ? '$value' : '$value $suffix',
          style: styles.numberMedium.copyWith(
            color: context.appColor(AppColors.onSurface),
          ),
        ),
        IconButton(
          onPressed: value + step <= max ? () => onChanged(value + step) : null,
          icon: const Icon(Icons.add),
          color: context.appColor(AppColors.primary),
          tooltip: S.of(context).actionIncrease,
        ),
        AppSpacing.xs.horizontalSpace,
      ],
    );
  }
}
