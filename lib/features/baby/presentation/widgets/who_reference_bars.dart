import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/baby/domain/entities/who_percentiles.dart';
import 'package:colette/features/baby/presentation/widgets/growth_chart_scale.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Traits OMS (P97, médiane, P3) et zone teintée entre P3 et P97, placés en
/// tête de `lineBarsData` : indices 0 à 2.
abstract final class WhoReferenceBars {
  /// Nombre de traits ajoutés avant la courbe des mesures.
  static const count = 3;

  static const _p97Index = 0;
  static const _p3Index = 2;

  /// Points de [points] compris dans l'axe horizontal de [scale].
  static List<WhoPercentiles> visible(
    List<WhoPercentiles> points,
    GrowthChartScale scale,
  ) => [
    for (final p in points)
      if (scale.xOf(p.date) >= scale.minX && scale.xOf(p.date) <= scale.maxX) p,
  ];

  static List<LineChartBarData> bars(
    BuildContext context,
    List<WhoPercentiles> points,
    GrowthChartScale scale,
  ) {
    final color = context.appColor(AppColors.growthReference);
    LineChartBarData bar(
      int Function(WhoPercentiles) value, {
      bool dashed = false,
    }) => LineChartBarData(
      spots: [
        for (final p in points) FlSpot(scale.xOf(p.date), value(p).toDouble()),
      ],
      color: dashed ? color : AppOpacity.medium.applyTo(color),
      barWidth: dashed ? AppStroke.regular.value : AppStroke.hairline.value,
      dashArray: dashed
          ? [AppSpacing.xs.value.toInt(), AppSpacing.xs.value.toInt()]
          : null,
      // Sans points : sert aussi à les distinguer de la courbe des mesures au toucher.
      dotData: const FlDotData(show: false),
    );
    return [
      bar((p) => p.p97),
      bar((p) => p.p50, dashed: true),
      bar((p) => p.p3),
    ];
  }

  /// Zone teintée entre P3 et P97.
  static BetweenBarsData band(BuildContext context) => BetweenBarsData(
    fromIndex: _p97Index,
    toIndex: _p3Index,
    color: AppOpacity.veryLight.applyTo(
      context.appColor(AppColors.growthReference),
    ),
  );
}
