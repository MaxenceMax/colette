import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/features/dashboard/presentation/widgets/bottle_schedule_sheet.dart';
import 'package:colette/features/dashboard/presentation/widgets/feeding_reference_sheet.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/duration_format.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carte « Prochain biberon » : quantité suggérée, fourchette, progression du jour.
class NextBottleCard extends ConsumerWidget {
  const NextBottleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final plan = ref.watch(feedingPlanProvider);
    if (plan == null) {
      return ColetteCardSurface(
        child: Text(
          s.feedingPlanUnavailable,
          style: styles.body.copyWith(
            color: context.appColor(AppColors.textSecondary),
          ),
        ),
      );
    }
    final now = ref.watch(currentMinuteProvider);
    final rolling = ref.watch(rollingIntakeProvider);
    final lastBottleAt = ref.watch(latestBottleProvider).value?.startAt;
    return ColetteCardSurface(
      // Haut réduit : l'IconButton du titre apporte déjà son propre padding.
      padding: AppSpacing.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.xs,
        bottom: AppSpacing.md,
      ),
      onTap: () =>
          showEventFormSheet(context, suggestedBottleMl: plan.suggestedMl),
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.xs.value,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.nextBottleTitle,
                  style: styles.overline.copyWith(
                    color: context.appColor(AppColors.primary),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => showBottleScheduleSheet(context),
                icon: const Icon(Icons.schedule),
                color: context.appColor(AppColors.textSecondary),
                tooltip: s.bottleScheduleTooltip,
              ),
              IconButton(
                onPressed: () => showFeedingReferenceSheet(context),
                icon: const Icon(Icons.info_outline),
                color: context.appColor(AppColors.textSecondary),
                tooltip: s.feedingReferenceTooltip,
              ),
            ],
          ),
          Row(
            crossAxisAlignment: .baseline,
            textBaseline: .alphabetic,
            spacing: AppSpacing.sm.value,
            children: [
              Text(
                s.bottleMl(plan.suggestedMl),
                style: styles.numberLarge.copyWith(
                  color: context.appColor(AppColors.primary),
                ),
              ),
              Expanded(
                child: _WhenText(plan: plan, now: now),
              ),
            ],
          ),
          if (lastBottleAt != null)
            Text(
              s.sinceLastBottle(
                formatDuration(now.difference(lastBottleAt), s),
              ),
              style: styles.small.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
          Text(
            s.bottleProgress(
              plan.bottlesGiven,
              plan.feedsPerDay,
              plan.givenMl,
              plan.dailyTargetMl,
            ),
            style: styles.small.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
          ClipRRect(
            borderRadius: AppRadius.round.circular,
            child: LinearProgressIndicator(
              value: plan.dailyTargetMl == 0
                  ? 0
                  : (plan.givenMl / plan.dailyTargetMl).clamp(0, 1),
              minHeight: AppSpacing.sm.value,
              backgroundColor: context.appColor(AppColors.primaryContainer),
              color: context.appColor(AppColors.primary),
            ),
          ),
          Text(
            s.bottleRollingIntake(rolling.bottles, rolling.ml),
            style: styles.small.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
          if (plan.isTargetOverridden)
            Text(
              s.feedingPlanAdjusted(plan.dailyTargetMl, plan.omsTargetMl),
              style: styles.small.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            )
          else if (plan.isEstimatedFromAge)
            Text(
              s.feedingPlanEstimated,
              style: styles.small.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

class _WhenText extends StatelessWidget {
  const _WhenText({required this.plan, required this.now});

  final FeedingPlan plan;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final late = plan.lateBy(now);
    if (late > Duration.zero) {
      return Text(
        s.nextBottleLate(late.inMinutes),
        style: styles.bodyMedium.copyWith(
          color: context.appColor(AppColors.warning),
        ),
      );
    }
    final end = formatHourMinute(plan.windowEnd);
    if (plan.isOpen(now)) {
      return Text(
        s.nextBottleGo(end),
        style: styles.bodyMedium.copyWith(
          color: context.appColor(AppColors.success),
        ),
      );
    }
    final text = plan.hasWindow
        ? s.nextBottleWindow(formatHourMinute(plan.windowStart), end)
        : s.nextBottleNow;
    return Text(
      text,
      style: styles.bodyMedium.copyWith(
        color: context.appColor(AppColors.textSecondary),
      ),
    );
  }
}
