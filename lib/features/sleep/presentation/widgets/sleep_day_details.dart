import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/sleep/domain/entities/sleep_day.dart';
import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';

/// Total, siestes et plus longue période du jour sélectionné.
class SleepDayDetails extends StatelessWidget {
  const SleepDayDetails({super.key, required this.day});

  final SleepDay day;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.sm.value,
        children: [
          Text(formatLongDate(day.day), style: styles.heading3),
          _StatRow(
            label: s.sleepDayTotal,
            value: formatSleepDuration(day.total, s),
          ),
          _StatRow(label: s.sleepDayNaps, value: '${day.napCount}'),
          _StatRow(
            label: s.sleepDayLongest,
            value: formatSleepDuration(day.longest, s),
          ),
        ],
      ),
    );
  }
}

/// Ligne libellé/valeur d'une statistique du jour.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: styles.body.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
        ),
        Text(value, style: styles.bodyMedium),
      ],
    );
  }
}
