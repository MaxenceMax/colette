import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/weight_trend.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dernier poids, date de la pesée et évolution depuis la précédente.
class WeightTrendSummary extends StatelessWidget {
  const WeightTrendSummary({super.key, required this.trend});

  final WeightTrend trend;

  /// Signe explicite : « +180 », « −40 », « 0 ».
  static String _signed(int value) => switch (value) {
    > 0 => '+$value',
    < 0 => '−${-value}',
    _ => '0',
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = styles.small.copyWith(
      color: context.appColor(AppColors.textSecondary),
    );
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(trend.latest.measuredAt);
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.xxs.value,
      children: [
        Text(
          s.weightGrams(trend.latest.grams),
          style: styles.numberMedium.copyWith(
            color: context.appColor(AppColors.primary),
          ),
        ),
        Text(s.weightMeasuredOn(date), style: secondary),
        Text(switch ((trend.deltaGrams, trend.days, trend.gramsPerDay)) {
          (final delta?, final days?, final perDay?) => s.weightTrendSince(
            _signed(delta),
            days,
            _signed(perDay),
          ),
          _ => s.weightTrendFirst,
        }, style: secondary),
      ],
    );
  }
}
