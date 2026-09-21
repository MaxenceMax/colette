import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:colette/shared/ui/care_type_ui.dart';
import 'package:flutter/material.dart';

/// Puce à cocher pour un soin : icône + libellé, colorée quand sélectionnée.
class CareChip extends StatelessWidget {
  const CareChip({
    super.key,
    required this.type,
    required this.selected,
    required this.onChanged,
  });

  final CareType type;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = context.appColor(type.color);
    final background = selected ? accent : context.appColor(AppColors.surface);
    final foreground = selected
        ? context.appColor(AppColors.onPrimary)
        : context.appColor(AppColors.onSurface);
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.round.circular,
        side: BorderSide(
          color: selected ? accent : context.appColor(AppColors.border),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!selected),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: AppSize.xl.value),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: AppSpacing.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: .min,
                spacing: AppSpacing.xs.value,
                children: [
                  Icon(type.icon, size: AppSize.xs.value, color: foreground),
                  Text(
                    type.label(S.of(context)),
                    style: Theme.of(context).coletteTextStyles.bodyMedium
                        .copyWith(color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
