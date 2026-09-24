import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:colette/shared/ui/care_type_ui.dart';
import 'package:flutter/material.dart';

/// Réglage d'un soin : libellé et interrupteur de suivi, puis « [−] fréquence [+] ».
/// Suivi coupé : la fréquence reste lisible, grisée, boutons inactifs.
class CareFrequencyRow extends StatelessWidget {
  const CareFrequencyRow({
    super.key,
    required this.type,
    required this.frequency,
    required this.maxTimesPerDay,
    required this.onChanged,
  });

  final CareType type;
  final CareFrequency frequency;
  final int maxTimesPerDay;
  final ValueChanged<CareFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final enabled = frequency.enabled;
    final muted = context.appColor(AppColors.textSecondary);
    final onSurface = context.appColor(AppColors.onSurface);
    final previous = enabled ? frequency.previous() : null;
    final next = enabled ? frequency.next(maxTimesPerDay) : null;
    final label = frequency.everyDays > 1
        ? s.careFrequencyEveryDays(frequency.everyDays)
        : s.careFrequencyPerDay(frequency.timesPerDay);
    return Column(
      children: [
        Row(
          spacing: AppSpacing.sm.value,
          children: [
            Icon(
              type.icon,
              color: enabled ? context.appColor(type.color) : muted,
            ),
            Expanded(
              child: Text(
                type.label(s),
                style: styles.body.copyWith(color: enabled ? onSurface : muted),
              ),
            ),
            Semantics(
              label: s.settingsCareTracked,
              child: Switch(
                value: enabled,
                onChanged: (value) =>
                    onChanged(frequency.copyWith(enabled: value)),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: previous == null ? null : () => onChanged(previous),
              icon: const Icon(Icons.remove),
              color: context.appColor(AppColors.primary),
              tooltip: s.actionDecrease,
            ),
            Expanded(
              child: Text(
                label,
                textAlign: .center,
                style: styles.bodyMedium.copyWith(
                  color: enabled ? onSurface : muted,
                ),
              ),
            ),
            IconButton(
              onPressed: next == null ? null : () => onChanged(next),
              icon: const Icon(Icons.add),
              color: context.appColor(AppColors.primary),
              tooltip: s.actionIncrease,
            ),
          ],
        ),
      ],
    );
  }
}
