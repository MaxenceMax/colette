import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/events/domain/use_cases/bottle_timer.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minuteur facultatif : 30 min de biberon puis 12 min à la verticale.
class BottleTimerSection extends ConsumerWidget {
  const BottleTimerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    ref.listen(bottleTimerPhaseProvider, (previous, next) {
      if (previous != null &&
          next != null &&
          previous.runtimeType != next.runtimeType) {
        HapticFeedback.mediumImpact();
      }
    });
    final phase = ref.watch(bottleTimerPhaseProvider);
    void start() => ref.read(bottleTimerControllerProvider.notifier).start();
    void stop() => ref.read(bottleTimerControllerProvider.notifier).reset();
    return switch (phase) {
      null => Align(
        alignment: .centerLeft,
        child: OutlinedButton.icon(
          onPressed: start,
          icon: const Icon(Icons.timer_outlined),
          label: Text(s.bottleTimerStart),
        ),
      ),
      BottleFeeding(:final remaining, :final progress) => _RunningPhase(
        label: s.bottleTimerFeeding,
        remaining: remaining,
        progress: progress,
        onStop: stop,
      ),
      BottleUpright(:final remaining, :final progress) => _RunningPhase(
        label: s.bottleTimerUpright,
        remaining: remaining,
        progress: progress,
        onStop: stop,
      ),
      BottleTimerDone() => Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: context.appColor(AppColors.categoryFeeding),
          ),
          AppSpacing.sm.horizontalSpace,
          Expanded(
            child: Text(
              s.bottleTimerDone,
              style: Theme.of(context).coletteTextStyles.bodyMedium,
            ),
          ),
          TextButton(onPressed: start, child: Text(s.bottleTimerRestart)),
        ],
      ),
    };
  }
}

class _RunningPhase extends StatelessWidget {
  const _RunningPhase({
    required this.label,
    required this.remaining,
    required this.progress,
    required this.onStop,
  });

  final String label;
  final Duration remaining;
  final double progress;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    final color = context.appColor(AppColors.categoryFeeding);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            Icon(Icons.timer_outlined, color: color),
            AppSpacing.sm.horizontalSpace,
            Expanded(child: Text(label, style: styles.bodyMedium)),
            Text(formatCountdown(remaining), style: styles.numberMedium),
            AppSpacing.sm.horizontalSpace,
            TextButton(
              onPressed: onStop,
              child: Text(S.of(context).bottleTimerStop),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: AppRadius.round.circular,
          child: LinearProgressIndicator(value: progress, color: color),
        ),
      ],
    );
  }
}
