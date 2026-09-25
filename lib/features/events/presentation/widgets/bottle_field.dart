import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/events/domain/use_cases/validate_care_event.dart';
import 'package:colette/features/events/presentation/widgets/bottle_timer_section.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';

/// Interrupteur « Biberon » + stepper de 10 ml + raccourcis + minuteur.
class BottleField extends StatelessWidget {
  const BottleField({
    super.key,
    required this.bottleMl,
    required this.onChanged,
  });

  static const presets = [60, 90, 120, 150, 180, 210];
  static const defaultMl = 120;

  /// `null` quand aucun biberon.
  final int? bottleMl;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final ml = bottleMl;
    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_drink_outlined,
              color: context.appColor(AppColors.categoryFeeding),
            ),
            AppSpacing.sm.horizontalSpace,
            Expanded(
              child: Text(
                s.careBottle,
                style: Theme.of(context).coletteTextStyles.bodyMedium,
              ),
            ),
            Switch(
              value: ml != null,
              onChanged: (on) => onChanged(on ? defaultMl : null),
            ),
          ],
        ),
        if (ml != null) ...[
          IntStepperRow(
            label: s.fieldQuantity,
            value: ml,
            min: ValidateCareEvent.minBottleMl,
            max: ValidateCareEvent.maxBottleMl,
            step: 10,
            suffix: s.unitMl,
            onChanged: onChanged,
          ),
          Wrap(
            spacing: AppSpacing.sm.value,
            children: [
              for (final preset in presets)
                ChoiceChip(
                  label: Text(s.bottleMl(preset)),
                  selected: preset == ml,
                  onSelected: (_) => onChanged(preset),
                ),
            ],
          ),
          AppSpacing.sm.verticalSpace,
          const BottleTimerSection(),
        ],
      ],
    );
  }
}
