import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/growth_trend.dart';
import 'package:colette/features/baby/domain/entities/who_percentiles.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/baby/presentation/providers/selected_growth_metric.dart';
import 'package:colette/features/baby/presentation/providers/who_curves_visibility.dart';
import 'package:colette/features/baby/presentation/widgets/growth_chart.dart';
import 'package:colette/features/baby/presentation/widgets/growth_format.dart';
import 'package:colette/features/baby/presentation/widgets/growth_measurement_sheet.dart';
import 'package:colette/features/baby/presentation/widgets/growth_trend_summary.dart';
import 'package:colette/features/baby/presentation/widgets/measurements_section.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Croissance : sélecteur de grandeur, dernière valeur, évolution, courbe
/// (avec repères OMS optionnels) et liste des mesures.
class GrowthPage extends ConsumerWidget {
  const GrowthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    // Écoute aussi pour garder le contrôleur autoDispose en vie pendant
    // les suppressions lancées depuis `MeasurementsSection`.
    ref.listen(babySettingsControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    final metric = ref.watch(selectedGrowthMetricProvider);
    final points = metric.seriesOf(
      ref.watch(measurementsProvider).value ?? const [],
    );
    final trend = ref.watch(growthTrendProvider(metric));
    return Scaffold(
      appBar: AppBar(title: Text(s.growthTitle)),
      body: ListView(
        padding: AppSpacing.md.horizontal,
        children: [
          AppSpacing.md.verticalSpace,
          _MetricSelector(selected: metric),
          AppSpacing.md.verticalSpace,
          if (trend == null)
            _EmptySection(metric: metric)
          else
            _ChartSection(metric: metric, points: points, trend: trend),
          SectionHeader(title: s.settingsMeasurementsSection),
          const MeasurementsSection(),
          AppSpacing.xl.verticalSpace,
        ],
      ),
    );
  }
}

/// Poids / Taille / Périmètre.
class _MetricSelector extends ConsumerWidget {
  const _MetricSelector({required this.selected});

  final GrowthMetric selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return SegmentedButton<GrowthMetric>(
      segments: [
        for (final metric in GrowthMetric.values)
          ButtonSegment(
            value: metric,
            label: Text(GrowthFormat.label(s, metric)),
          ),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) =>
          ref.read(selectedGrowthMetricProvider.notifier).set(selection.first),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.metric});

  final GrowthMetric metric;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      children: [
        EmptyState(
          icon: switch (metric) {
            GrowthMetric.weight => Icons.monitor_weight_outlined,
            GrowthMetric.length => Icons.straighten,
            GrowthMetric.headCircumference => Icons.child_care_outlined,
          },
          message: GrowthFormat.empty(s, metric),
        ),
        FilledButton.icon(
          onPressed: () => showGrowthMeasurementSheet(context),
          icon: const Icon(Icons.add),
          label: Text(s.actionAddMeasurement),
        ),
      ],
    );
  }
}

class _ChartSection extends ConsumerWidget {
  const _ChartSection({
    required this.metric,
    required this.points,
    required this.trend,
  });

  final GrowthMetric metric;
  final List<GrowthPoint> points;
  final GrowthTrend trend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final hasSex = ref.watch(babyProfileProvider).value?.sex != null;
    final showWho = hasSex && ref.watch(whoCurvesVisibilityProvider);
    final reference = showWho
        ? ref.watch(whoReferenceProvider(metric))
        : const <WhoPercentiles>[];
    final small = Theme.of(context).coletteTextStyles.small
        .copyWith(color: context.appColor(AppColors.textSecondary));
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.md.value,
        children: [
          GrowthTrendSummary(trend: trend),
          AspectRatio(
            aspectRatio: GrowthChart.aspectRatio,
            child: GrowthChart(
              metric: metric,
              points: points,
              reference: reference,
            ),
          ),
          Text(s.growthCurveHint, style: small),
          _WhoToggle(hasSex: hasSex, visible: showWho),
          if (showWho)
            Text(
              reference.isEmpty ? s.whoCurvesOutOfRange : s.whoCurvesLegend,
              style: small,
            ),
        ],
      ),
    );
  }
}

/// Interrupteur des courbes OMS, commun aux trois grandeurs, inactif tant que
/// le sexe n'est pas renseigné.
class _WhoToggle extends ConsumerWidget {
  const _WhoToggle({required this.hasSex, required this.visible});

  final bool hasSex;
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(s.whoCurvesToggle, style: styles.bodyMedium),
      subtitle: hasSex
          ? null
          : Text(
              s.whoCurvesNeedsSex,
              style: styles.small.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
      value: visible,
      onChanged: hasSex
          ? (value) => ref.read(whoCurvesVisibilityProvider.notifier).set(value)
          : null,
    );
  }
}
