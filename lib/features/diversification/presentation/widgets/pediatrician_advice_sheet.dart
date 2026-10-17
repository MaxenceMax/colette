import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/pediatrician_advice.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre les consignes du pédiatre.
Future<void> showPediatricianAdviceSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const PediatricianAdviceSheet(),
    );

/// Consignes du pédiatre réunies : étapes par âge, étape du moment, à éviter.
class PediatricianAdviceSheet extends ConsumerWidget {
  const PediatricianAdviceSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advice = ref.watch(foodCatalogProvider).value?.pediatricianAdvice;
    if (advice == null) return const SizedBox.shrink();
    final ageMonths = ref.watch(diversificationTimelineProvider)?.ageMonths;
    final current = ageMonths == null ? null : advice.currentStep(ageMonths);
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return ListView(
      padding: AppSpacing.lg.all,
      children: [
        Text(advice.title, style: styles.heading2),
        AppSpacing.xs.verticalSpace,
        Text(advice.author, style: styles.label),
        Text(advice.scope, style: styles.body.copyWith(color: secondary)),
        for (final step in advice.steps)
          _StepSection(step: step, isCurrent: step == current),
        SectionHeader(title: s.pediatricianAvoid),
        Text(advice.avoid, style: styles.body),
      ],
    );
  }
}

class _StepSection extends StatelessWidget {
  const _StepSection({required this.step, required this.isCurrent});

  final AdviceStep step;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: .start,
      children: [
        SectionHeader(
          title: s.pediatricianStepFrom(step.fromMonths),
          trailing: isCurrent ? const _CurrentBadge() : null,
        ),
        for (final item in step.items) ...[
          _Bullet(text: item.text),
          for (final detail in item.details)
            Padding(
              padding: AppSpacing.md.left,
              child: _Bullet(text: detail),
            ),
        ],
      ],
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColor(AppColors.primaryContainer),
        borderRadius: AppRadius.round.circular,
      ),
      child: Padding(
        padding: AppSpacing.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          S.of(context).pediatricianCurrentStep,
          style: Theme.of(context).coletteTextStyles.small
              .copyWith(color: context.appColor(AppColors.primary)),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.xs.vertical,
      child: Row(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Padding(
            padding: AppSpacing.sm.top,
            child: Icon(
              Icons.circle,
              size: AppSize.nano.value,
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(text, style: Theme.of(context).coletteTextStyles.body),
          ),
        ],
      ),
    );
  }
}
