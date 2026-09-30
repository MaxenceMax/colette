import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/widgets/timeline_item_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Alerte d'Aujourd'hui : RDV passé dont la visite n'est pas encore marquée
/// comme faite ; rien sinon. Tap : feuille de l'élément.
class AwaitingAppointmentCard extends ConsumerWidget {
  const AwaitingAppointmentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(medicalTimelineProvider);
    final item = timeline?.awaitingConfirmation.firstOrNull;
    final at = item?.appointmentAt;
    if (item == null || at == null) return const SizedBox.shrink();
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final warning = context.appColor(AppColors.warning);
    return Padding(
      padding: AppSpacing.md.top,
      child: ColetteCardSurface(
        borderColor: AppColors.warning,
        onTap: () => showTimelineItemSheet(context, item),
        child: Row(
          spacing: AppSpacing.sm.value,
          children: [
            Icon(Icons.event_busy_outlined, color: warning),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: AppSpacing.xxs.value,
                children: [
                  Text(
                    s.dashboardAppointmentAwaiting,
                    style: styles.overline.copyWith(color: warning),
                  ),
                  Text(timelineItemTitle(s, item), style: styles.bodyMedium),
                  Text(
                    formatDayAndTime(at),
                    style: styles.small.copyWith(
                      color: context.appColor(AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: context.appColor(AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
