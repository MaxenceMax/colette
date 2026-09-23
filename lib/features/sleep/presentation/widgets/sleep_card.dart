import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/sleep/domain/entities/sleep_status.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_controller.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_form_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte « Sommeil » de l'accueil : état actuel, chrono, total sur 24 h.
class SleepCard extends ConsumerWidget {
  const SleepCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    ref.listen(sleepControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    // Garde le contrôleur autoDispose vivant pendant l'await des boutons.
    final isLoading = ref.watch(sleepControllerProvider) is AsyncLoading;
    final summary = ref.watch(sleepSummaryProvider);
    if (summary == null) return const SizedBox.shrink();
    return Padding(
      padding: AppSpacing.md.top,
      child: ColetteCardSurface(
        onTap: () => context.push(AppRoutes.sleep),
        child: Column(
          crossAxisAlignment: .stretch,
          spacing: AppSpacing.sm.value,
          children: [
            const _Header(),
            _StatusSection(status: summary.status, isLoading: isLoading),
            _TotalLine(last24h: summary.last24h),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final primary = context.appColor(AppColors.primary);
    return Row(
      spacing: AppSpacing.xs.value,
      children: [
        Icon(Icons.bedtime_outlined, size: AppSize.xs.value, color: primary),
        Expanded(
          child: Text(
            s.sleepCardTitle,
            style: Theme.of(context).coletteTextStyles.overline
                .copyWith(color: primary),
          ),
        ),
        IconButton(
          onPressed: () => showSleepFormSheet(context),
          icon: const Icon(Icons.add),
          color: primary,
          tooltip: s.sleepAddPast,
        ),
        Icon(
          Icons.chevron_right,
          color: context.appColor(AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatusSection extends ConsumerWidget {
  const _StatusSection({required this.status, required this.isLoading});

  final SleepStatus status;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final now = ref.watch(currentMinuteProvider);
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.xs.value,
      children: switch (status) {
        Asleep(:final session) => [
          Text(
            s.sleepAsleepFor(
              formatSleepDuration(now.difference(session.startAt), s),
            ),
            style: styles.heading2,
          ),
          Text(
            s.sleepAsleepSince(
              session.kind.label(s),
              formatHourMinute(session.startAt),
            ),
            style: styles.small.copyWith(color: secondary),
          ),
          FilledButton(
            onPressed: isLoading
                ? null
                : () => ref.read(sleepControllerProvider.notifier).wakeUp(),
            child: Text(s.sleepWakeUpAction),
          ),
        ],
        ForgottenWake(:final session) => [
          Text(
            s.sleepAsleepFor(
              formatSleepDuration(now.difference(session.startAt), s),
            ),
            style: styles.heading2,
          ),
          Text(
            s.sleepForgottenWake,
            style: styles.small.copyWith(
              color: context.appColor(AppColors.warning),
            ),
          ),
          FilledButton(
            onPressed: () => showSleepFormSheet(
              context,
              initial: session,
              pickEndOnOpen: true,
            ),
            child: Text(s.sleepEnterWakeAction),
          ),
        ],
        Awake(:final since) => [
          Text(switch (since) {
            null => s.sleepNoneYet,
            final since => s.sleepAwakeFor(
              formatSleepDuration(now.difference(since), s),
            ),
          }, style: styles.heading2),
          OutlinedButton(
            onPressed: isLoading
                ? null
                : () => ref.read(sleepControllerProvider.notifier).fallAsleep(),
            child: Text(s.sleepFallAsleepAction),
          ),
        ],
      },
    );
  }
}

class _TotalLine extends ConsumerWidget {
  const _TotalLine({required this.last24h});

  final Duration last24h;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final band = ref.watch(sleepAgeBandProvider);
    final total = formatSleepDuration(last24h, s);
    return Text(
      band == null
          ? s.sleepLast24h(total)
          : s.sleepLast24hWithReference(total, band.minHours, band.maxHours),
      style: Theme.of(context).coletteTextStyles.small
          .copyWith(color: context.appColor(AppColors.textSecondary)),
    );
  }
}
