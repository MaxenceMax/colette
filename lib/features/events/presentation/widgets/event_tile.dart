import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/care_type_ui.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';

/// Ligne du journal : heure, icônes des soins, biberon, note. Glisser pour supprimer.
class EventTile extends StatelessWidget {
  const EventTile({
    super.key,
    required this.event,
    required this.onTap,
    required this.onConfirmDelete,
  });

  final CareEvent event;
  final VoidCallback onTap;

  /// Doit renvoyer `true` pour confirmer la suppression, puis la réaliser.
  final Future<bool> Function() onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return Padding(
      padding: AppSpacing.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Dismissible(
        key: ValueKey(event.id),
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
                    formatHourMinute(event.startAt),
                    style: styles.bodyMedium,
                  ),
                  if (!event.endAt.isAtSameMomentAs(event.startAt))
                    Text(
                      formatHourMinute(event.endAt),
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
                    Wrap(
                      spacing: AppSpacing.xs.value,
                      runSpacing: AppSpacing.xs.value,
                      crossAxisAlignment: .center,
                      children: [
                        for (final type in event.checkedCares)
                          _CareDot(
                            icon: type.icon,
                            color: context.appColor(type.color),
                          ),
                        if (event.bottleMl case final ml?)
                          _BottleBadge(label: s.bottleMl(ml)),
                      ],
                    ),
                    if (event.note case final note?)
                      Text(
                        note,
                        maxLines: 1,
                        overflow: .ellipsis,
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

class _CareDot extends StatelessWidget {
  const _CareDot({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.md.value,
      height: AppSize.md.value,
      decoration: BoxDecoration(
        color: AppOpacity.light.applyTo(color),
        borderRadius: AppRadius.round.circular,
      ),
      child: Icon(icon, size: AppSize.xs.value, color: color),
    );
  }
}

class _BottleBadge extends StatelessWidget {
  const _BottleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: context.appColor(AppColors.categoryFeeding),
        borderRadius: AppRadius.round.circular,
      ),
      child: Text(
        label,
        style: Theme.of(context).coletteTextStyles.label
            .copyWith(color: context.appColor(AppColors.onPrimary)),
      ),
    );
  }
}
