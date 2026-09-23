import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/widgets/weight_chart_scale.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Courbe des pesées ; `compact` masque axes, grille et infobulle.
class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.weights, this.compact = false});

  /// Proportions de la courbe pleine taille.
  static const aspectRatio = 1.6;

  /// Tolérance, en jours, pour reconnaître l'abscisse d'une pesée.
  static const _xTolerance = 1e-6;

  /// Pesées à tracer, au moins une, dans n'importe quel ordre.
  final List<WeightEntry> weights;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sorted = [...weights]
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    final scale = WeightChartScale.fromWeights(sorted);
    final primary = context.appColor(AppColors.primary);
    final surface = context.appColor(AppColors.surface);
    return LineChart(
      duration: AppDuration.normal.value,
      LineChartData(
        minX: scale.minX,
        maxX: scale.maxX,
        minY: scale.minGrams.toDouble(),
        maxY: scale.maxGrams.toDouble(),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: !compact,
          drawVerticalLine: false,
          horizontalInterval: scale.stepGrams.toDouble(),
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
            : _touch(context, sorted),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (final w in sorted)
                FlSpot(scale.xOf(w.measuredAt), w.grams.toDouble()),
            ],
            color: primary,
            barWidth: compact ? AppStroke.regular.value : AppStroke.thick.value,
            isStrokeCapRound: true,
            isStrokeJoinRound: true,
            belowBarData: BarAreaData(
              show: true,
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

  FlTitlesData _titles(
    BuildContext context,
    List<WeightEntry> sorted,
    WeightChartScale scale,
  ) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final kgFormat = NumberFormat('0.0#', locale);
    final dateFormat = DateFormat.MMMd(locale);
    final style = Theme.of(context).coletteTextStyles.small
        .copyWith(color: context.appColor(AppColors.textSecondary));
    final first = sorted.first.measuredAt;
    final last = sorted.last.measuredAt;
    // Dates affichées : première et dernière pesée, une seule si même jour.
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
          interval: scale.stepGrams.toDouble(),
          reservedSize: AppSize.xxl.value,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            child: Text(
              s.weightKg(kgFormat.format(value / 1000)),
              style: style,
            ),
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

  LineTouchData _touch(BuildContext context, List<WeightEntry> sorted) {
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
            LineTooltipItem(
              s.weightGrams(sorted[spot.spotIndex].grams),
              styles.bodyMedium.copyWith(color: onPrimary),
              children: [
                TextSpan(
                  text:
                      '\n${dateFormat.format(sorted[spot.spotIndex].measuredAt)}',
                  style: styles.small.copyWith(color: onPrimary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
