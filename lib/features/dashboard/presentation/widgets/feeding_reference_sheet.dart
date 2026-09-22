import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_age_band.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_reference.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/features/dashboard/presentation/widgets/feeding_target_section.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Ouvre la feuille « Repères OMS ».
Future<void> showFeedingReferenceSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FeedingReferenceSheet(),
    );

/// Repères OMS par âge et au poids, ligne du jour surlignée, cible ajustable.
class FeedingReferenceSheet extends ConsumerWidget {
  const FeedingReferenceSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final profile = ref.watch(babyProfileProvider).value;
    final reference = ref.watch(feedingReferenceProvider);
    final plan = ref.watch(feedingPlanProvider);
    if (profile == null || reference == null || plan == null) {
      return const SizedBox.shrink();
    }
    final styles = Theme.of(context).coletteTextStyles;
    return ListView(
      shrinkWrap: true,
      padding: AppSpacing.lg.all,
      children: [
        Text(s.feedingReferenceTitle, style: styles.heading2),
        AppSpacing.xs.verticalSpace,
        Text(
          s.feedingReferenceSource,
          style: styles.small.copyWith(
            color: context.appColor(AppColors.textSecondary),
          ),
        ),
        AppSpacing.lg.verticalSpace,
        _AgeTableSection(current: reference.ageBand),
        AppSpacing.lg.verticalSpace,
        _WeightRuleSection(reference: reference),
        AppSpacing.lg.verticalSpace,
        FeedingTargetSection(profile: profile, omsTargetMl: plan.omsTargetMl),
      ],
    );
  }
}

class _AgeTableSection extends StatelessWidget {
  const _AgeTableSection({required this.current});

  final FeedingAgeBand current;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.xs.value,
      children: [
        _SectionTitle(s.feedingReferenceAgeTitle),
        for (final band in FeedingAgeBand.values)
          _ReferenceRow(
            label: _bandLabel(s, band),
            value: s.feedingMlPerDay(band.dailyMl),
            highlighted: band == current,
          ),
      ],
    );
  }

  static String _bandLabel(S s, FeedingAgeBand band) => switch (band) {
    FeedingAgeBand.day1 => s.feedingDayOfLife(1),
    FeedingAgeBand.day2 => s.feedingDayOfLife(2),
    FeedingAgeBand.day3 => s.feedingDayOfLife(3),
    FeedingAgeBand.day4 => s.feedingDayOfLife(4),
    FeedingAgeBand.day5 => s.feedingDayOfLife(5),
    FeedingAgeBand.day6ToMonth1 => s.feedingAgeBandDay6ToMonth1,
    FeedingAgeBand.month1To2 => s.feedingAgeBandMonth1To2,
    FeedingAgeBand.month2To4 => s.feedingAgeBandMonth2To4,
    FeedingAgeBand.month4To6 => s.feedingAgeBandMonth4To6,
    FeedingAgeBand.month6Plus => s.feedingAgeBandMonth6Plus,
  };
}

class _WeightRuleSection extends StatelessWidget {
  const _WeightRuleSection({required this.reference});

  /// Jour de vie à partir duquel le plafond de 150 ml/kg s'applique.
  static const plateauDay = 6;

  static final _kgFormat = NumberFormat('0.0', 'fr');

  final FeedingReference reference;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final grams = reference.weightGrams;
    final weightTargetMl = reference.weightTargetMl;
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.xs.value,
      children: [
        _SectionTitle(s.feedingReferenceWeightTitle),
        for (var day = 1; day < plateauDay; day++)
          _ReferenceRow(
            label: s.feedingDayOfLife(day),
            value: s.feedingMlPerKg(ComputeFeedingPlan.mlPerKg(day)),
            highlighted: reference.dayOfLife == day,
          ),
        _ReferenceRow(
          label: s.feedingWeightRuleDay6Plus,
          value: s.feedingMlPerKg(ComputeFeedingPlan.mlPerKg(plateauDay)),
          highlighted: reference.dayOfLife >= plateauDay,
        ),
        Text(
          grams == null || weightTargetMl == null
              ? s.feedingPlanEstimated
              : s.feedingWeightCalc(
                  reference.mlPerKg,
                  _kgFormat.format(grams / 1000),
                  weightTargetMl,
                ),
          style: styles.bodyMedium.copyWith(
            color: context.appColor(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).coletteTextStyles.heading3
        .copyWith(color: context.appColor(AppColors.textSecondary)),
  );
}

/// Ligne « libellé … valeur », surlignée quand c'est celle du jour.
class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({
    required this.label,
    required this.value,
    required this.highlighted,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    return Container(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? context.appColor(AppColors.primaryContainer)
            : null,
        borderRadius: AppRadius.sm.circular,
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              style: highlighted ? styles.bodyMedium : styles.body,
            ),
          ),
          Text(
            value,
            textAlign: .end,
            softWrap: false,
            overflow: .fade,
            style: styles.numberMedium.copyWith(
              color: context.appColor(
                highlighted ? AppColors.primary : AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
