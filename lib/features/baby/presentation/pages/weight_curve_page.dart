import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/domain/entities/weight_trend.dart';
import 'package:colette/features/baby/domain/entities/who_weight_percentiles.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/baby/presentation/providers/who_curves_visibility.dart';
import 'package:colette/features/baby/presentation/widgets/add_weight_sheet.dart';
import 'package:colette/features/baby/presentation/widgets/weight_chart.dart';
import 'package:colette/features/baby/presentation/widgets/weight_trend_summary.dart';
import 'package:colette/features/baby/presentation/widgets/weights_section.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Courbe de poids : dernière pesée, évolution, courbe (avec repères OMS
/// optionnels) et liste des pesées.
class WeightCurvePage extends ConsumerWidget {
  const WeightCurvePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    // Écoute aussi pour garder le contrôleur autoDispose en vie pendant
    // les suppressions lancées depuis `WeightsSection`.
    ref.listen(babySettingsControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    final weights = ref.watch(weightsProvider).value ?? const <WeightEntry>[];
    final trend = ref.watch(weightTrendProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.weightCurveTitle)),
      body: ListView(
        padding: AppSpacing.md.horizontal,
        children: [
          if (trend == null)
            const _EmptySection()
          else ...[
            AppSpacing.md.verticalSpace,
            _ChartSection(weights: weights, trend: trend),
            SectionHeader(title: s.settingsWeightsSection),
            const WeightsSection(),
          ],
          AppSpacing.xl.verticalSpace,
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      children: [
        EmptyState(
          icon: Icons.monitor_weight_outlined,
          message: s.weightCurveEmpty,
        ),
        FilledButton.icon(
          onPressed: () => showAddWeightSheet(context),
          icon: const Icon(Icons.add),
          label: Text(s.settingsAddWeight),
        ),
      ],
    );
  }
}

class _ChartSection extends ConsumerWidget {
  const _ChartSection({required this.weights, required this.trend});

  final List<WeightEntry> weights;
  final WeightTrend trend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final hasSex = ref.watch(babyProfileProvider).value?.sex != null;
    final showWho = hasSex && ref.watch(whoCurvesVisibilityProvider);
    final reference = showWho
        ? ref.watch(whoWeightReferenceProvider)
        : const <WhoWeightPercentiles>[];
    final small = Theme.of(context).coletteTextStyles.small
        .copyWith(color: context.appColor(AppColors.textSecondary));
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.md.value,
        children: [
          WeightTrendSummary(trend: trend),
          AspectRatio(
            aspectRatio: WeightChart.aspectRatio,
            child: WeightChart(weights: weights, reference: reference),
          ),
          Text(s.weightCurveHint, style: small),
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

/// Interrupteur des courbes OMS, inactif tant que le sexe n'est pas renseigné.
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
