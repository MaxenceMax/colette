import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/growth_trend.dart';
import 'package:colette/features/baby/presentation/widgets/growth_format.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dernière valeur d'une grandeur, date de la mesure et évolution depuis la précédente.
class GrowthTrendSummary extends StatelessWidget {
  const GrowthTrendSummary({super.key, required this.trend});

  final GrowthTrend trend;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = styles.small.copyWith(
      color: context.appColor(AppColors.textSecondary),
    );
    final isWeight = trend.metric == GrowthMetric.weight;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(trend.latestAt);
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.xxs.value,
      children: [
        Text(
          GrowthFormat.value(s, trend.metric, trend.latestValue),
          style: styles.numberMedium.copyWith(
            color: context.appColor(AppColors.primary),
          ),
        ),
        Text(
          isWeight ? s.weightMeasuredOn(date) : s.measurementMeasuredOn(date),
          style: secondary,
        ),
        Text(_evolution(s, isWeight: isWeight), style: secondary),
      ],
    );
  }

  String _evolution(S s, {required bool isWeight}) {
    String signed(int value) => GrowthFormat.signedDelta(trend.metric, value);
    return switch ((trend.delta, trend.days, trend.perDay)) {
      (final delta?, final days?, final perDay?) when isWeight =>
        s.weightTrendSince(signed(delta), days, signed(perDay)),
      (final delta?, final days?, _) => s.measurementTrendSinceCm(
        signed(delta),
        days,
      ),
      _ => isWeight ? s.weightTrendFirst : s.measurementTrendFirst,
    };
  }
}
