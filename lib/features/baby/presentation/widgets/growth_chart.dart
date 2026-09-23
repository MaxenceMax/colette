import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/who_percentiles.dart';
import 'package:colette/features/baby/presentation/widgets/growth_chart_scale.dart';
import 'package:colette/features/baby/presentation/widgets/growth_format.dart';
import 'package:colette/features/baby/presentation/widgets/who_reference_bars.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Courbe d'une grandeur de croissance, avec référence OMS optionnelle ;
/// `compact` masque axes, grille et infobulle.
class GrowthChart extends StatelessWidget {
  const GrowthChart({
    super.key,
    required this.metric,
    required this.points,
    this.reference = const [],
    this.compact = false,
  });

  /// Proportions de la courbe pleine taille.
  static const aspectRatio = 1.6;

  /// Tolérance, en jours, pour reconnaître l'abscisse d'une mesure.
  static const _xTolerance = 1e-6;

  final GrowthMetric metric;

  /// Points à tracer, au moins un, dans n'importe quel ordre.
  final List<GrowthPoint> points;

  /// Percentiles OMS à tracer derrière la courbe ; vide pour les masquer.
  final List<WhoPercentiles> reference;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sorted = [...points]..sort((a, b) => a.at.compareTo(b.at));
    final firstScale = GrowthChartScale.fromPoints(sorted, metric: metric);
    final shown = WhoReferenceBars.visible(reference, firstScale);
    final scale = shown.isEmpty
        ? firstScale
        : GrowthChartScale.fromPoints(
            sorted,
            metric: metric,
            extraValues: [
              for (final p in shown) ...[p.p3, p.p97],
            ],
          );
    final valueBarIndex = shown.isEmpty ? 0 : WhoReferenceBars.count;
    final primary = context.appColor(AppColors.primary);
    final surface = context.appColor(AppColors.surface);
    return LineChart(
      duration: AppDuration.normal.value,
      LineChartData(
        minX: scale.minX,
        maxX: scale.maxX,
        minY: scale.minValue.toDouble(),
        maxY: scale.maxValue.toDouble(),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: !compact,
          drawVerticalLine: false,
          horizontalInterval: scale.step.toDouble(),
          getDrawingHorizontalLine: (_) => FlLine(
            color: context.appColor(AppColors.border),
            strokeWidth: AppStroke.hairline.value,
          ),
        ),
        titlesData: compact
            ? const FlTitlesData(show: false)
            : _titles(context, sorted, scale),
        lineTouchData: compact
            ? const LineTouchData(enabled: false)
            : _touch(context, sorted, valueBarIndex),
        betweenBarsData: [if (shown.isNotEmpty) WhoReferenceBars.band(context)],
        lineBarsData: [
          if (shown.isNotEmpty) ...WhoReferenceBars.bars(context, shown, scale),
          LineChartBarData(
            spots: [
              for (final p in sorted)
                FlSpot(scale.xOf(p.at), p.value.toDouble()),
            ],
            color: primary,
            barWidth: compact ? AppStroke.regular.value : AppStroke.thick.value,
            isStrokeCapRound: true,
            isStrokeJoinRound: true,
            belowBarData: BarAreaData(
              // La zone OMS remplace le remplissage sous la courbe.
              show: shown.isEmpty,
              color: AppOpacity.veryLight.applyTo(primary),
            ),
            dotData: FlDotData(
              checkToShowDot: (spot, bar) => !compact || spot == bar.spots.last,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: AppSpacing.xs.value,
                color: primary,
                strokeColor: surface,
                strokeWidth: AppStroke.regular.value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Graduation verticale : kilogrammes pour le poids, centimètres sinon.
  String _axisLabel(S s, String locale, double value) => switch (metric) {
    GrowthMetric.weight => s.weightKg(
      NumberFormat('0.0#', locale).format(value / 1000),
    ),
    GrowthMetric.length || GrowthMetric.headCircumference => s.measurementCm(
      NumberFormat('0.#', locale).format(value / 10),
    ),
  };

  FlTitlesData _titles(
    BuildContext context,
    List<GrowthPoint> sorted,
    GrowthChartScale scale,
  ) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.MMMd(locale);
    final style = Theme.of(context).coletteTextStyles.small
        .copyWith(color: context.appColor(AppColors.textSecondary));
    final first = sorted.first.at;
    final last = sorted.last.at;
    // Dates affichées : première et dernière mesure, une seule si même jour.
    final labelled = {
      scale.xOf(first): first,
      if (!DateUtils.isSameDay(first, last)) scale.xOf(last): last,
    };
    const hidden = AxisTitles();
    return FlTitlesData(
      topTitles: hidden,
      rightTitles: hidden,
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: scale.step.toDouble(),
          reservedSize: AppSize.xxl.value,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            child: Text(_axisLabel(s, locale, value), style: style),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: scale.dateInterval,
          reservedSize: AppSize.md.value,
          getTitlesWidget: (value, meta) {
            final date = labelled.entries
                .where((e) => (e.key - value).abs() < _xTolerance)
                .firstOrNull
                ?.value;
            if (date == null) return const SizedBox.shrink();
            return SideTitleWidget(
              meta: meta,
              fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
              child: Text(dateFormat.format(date), style: style),
            );
          },
        ),
      ),
    );
  }

  LineTouchData _touch(
    BuildContext context,
    List<GrowthPoint> sorted,
    int valueBarIndex,
  ) {
    final s = S.of(context);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );
    final styles = Theme.of(context).coletteTextStyles;
    final onPrimary = context.appColor(AppColors.onPrimary);
    final border = context.appColor(AppColors.border);
    return LineTouchData(
      getTouchedSpotIndicator: (bar, indexes) => [
        for (final _ in indexes)
          // Traits OMS (sans points) : pas d'indicateur.
          if (!bar.dotData.show)
            null
          else
            TouchedSpotIndicatorData(
              FlLine(color: border, strokeWidth: AppStroke.regular.value),
              FlDotData(
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: AppSpacing.sm.value - AppSpacing.xxs.value,
                  color: context.appColor(AppColors.primary),
                  strokeColor: context.appColor(AppColors.surface),
                  strokeWidth: AppStroke.thick.value,
                ),
              ),
            ),
      ],
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => context.appColor(AppColors.primary),
        tooltipBorderRadius: AppRadius.sm.circular,
        tooltipPadding: AppSpacing.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        getTooltipItems: (spots) => [
          for (final spot in spots)
            if (spot.barIndex != valueBarIndex)
              null
            else
              LineTooltipItem(
                GrowthFormat.value(s, metric, sorted[spot.spotIndex].value),
                styles.bodyMedium.copyWith(color: onPrimary),
                children: [
                  TextSpan(
                    text: '\n${dateFormat.format(sorted[spot.spotIndex].at)}',
                    style: styles.small.copyWith(color: onPrimary),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}
