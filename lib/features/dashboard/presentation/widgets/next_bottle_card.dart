import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carte « Prochain biberon » : quantité suggérée, heure, progression du jour.
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
    return ColetteCardSurface(
      onTap: () =>
          showEventFormSheet(context, suggestedBottleMl: plan.suggestedMl),
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.xs.value,
        children: [
          Text(
            s.nextBottleTitle,
            style: styles.overline.copyWith(
              color: context.appColor(AppColors.primary),
            ),
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
          if (plan.isEstimatedFromAge)
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
    final text = plan.nextBottleAt.isAfter(now)
        ? s.nextBottleAt(formatHourMinute(plan.nextBottleAt))
        : s.nextBottleNow;
    return Text(
      text,
      style: styles.bodyMedium.copyWith(
        color: context.appColor(AppColors.textSecondary),
      ),
    );
  }
}
