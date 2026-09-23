import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';

/// Ligne du Journal pour un sommeil : heures, type, durée. Glisser pour supprimer.
class SleepTile extends StatelessWidget {
  const SleepTile({
    super.key,
    required this.session,
    required this.now,
    required this.onTap,
    required this.onConfirmDelete,
  });

  final SleepSession session;
  final DateTime now;
  final VoidCallback onTap;

  /// Doit renvoyer `true` pour confirmer la suppression, puis la réaliser.
  final Future<bool> Function() onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final duration = formatSleepDuration(session.durationUntil(now), s);
    return Padding(
      padding: AppSpacing.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Dismissible(
        key: ValueKey(session.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => onConfirmDelete(),
        background: Container(
          alignment: .centerRight,
          padding: AppSpacing.md.horizontal,
          decoration: BoxDecoration(
            color: context.appColor(AppColors.error),
            borderRadius: AppRadius.lg.circular,
          ),
          child: Icon(
            Icons.delete_outline,
            color: context.appColor(AppColors.onPrimary),
          ),
        ),
        child: ColetteCardSurface(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: .start,
            children: [
              Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    formatHourMinute(session.startAt),
                    style: styles.bodyMedium,
                  ),
                  if (session.endAt case final end?)
                    Text(
                      formatHourMinute(end),
                      style: styles.small.copyWith(color: secondary),
                    ),
                ],
              ),
              AppSpacing.md.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: AppSpacing.xs.value,
                  children: [
                    Row(
                      spacing: AppSpacing.xs.value,
                      children: [
                        Icon(
                          Icons.bedtime_outlined,
                          size: AppSize.xs.value,
                          color: context.appColor(AppColors.sleepNight),
                        ),
                        Text(session.kind.label(s), style: styles.bodyMedium),
                      ],
                    ),
                    Text(
                      session.isOngoing
                          ? s.sleepOngoingFor(duration)
                          : duration,
                      style: styles.small.copyWith(color: secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
