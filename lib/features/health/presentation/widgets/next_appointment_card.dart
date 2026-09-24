import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/domain/entities/appointment_proximity.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/widgets/timeline_item_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carte « Prochain rendez-vous » de l'onglet Santé : le RDV programmé le
/// plus proche en évidence, ou « Pas de rendez-vous programmé ».
class NextAppointmentCard extends ConsumerWidget {
  const NextAppointmentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final item = ref.watch(medicalTimelineProvider)?.nextAppointment;
    final proximity = ref.watch(nextAppointmentProximityProvider);
    final appointmentAt = item?.appointmentAt;
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.sm.value,
      children: [
        Padding(
          padding: AppSpacing.md.top,
          child: Text(
            s.healthNextAppointment,
            style: styles.overline.copyWith(
              color: context.appColor(AppColors.primary),
            ),
          ),
        ),
        if (item == null || proximity == null || appointmentAt == null)
          const _EmptyCard()
        else
          _AppointmentBody(
            item: item,
            appointmentAt: appointmentAt,
            proximity: proximity,
          ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    final secondary = context.appColor(AppColors.textSecondary);
    return ColetteCardSurface(
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          Icon(Icons.event_busy_outlined, color: secondary),
          Expanded(
            child: Text(
              S.of(context).healthNoAppointment,
              style: Theme.of(context).coletteTextStyles.body
                  .copyWith(color: secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentBody extends ConsumerWidget {
  const _AppointmentBody({
    required this.item,
    required this.appointmentAt,
    required this.proximity,
  });

  final MedicalTimelineItem item;
  final DateTime appointmentAt;
  final AppointmentProximity proximity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final today = ref.watch(todayProvider);
    final countdown = switch (proximity) {
      AppointmentProximity.today || AppointmentProximity.tomorrow => null,
      AppointmentProximity.soon || AppointmentProximity.later => s.healthInDays(
        calendarDaysBetween(today, appointmentAt.dateOnly),
      ),
    };
    final details = [?item.practitioner, ?countdown].join(' · ');
    return ColetteCardSurface(
      backgroundColor: AppColors.primaryContainer,
      borderColor: AppColors.primaryContainer,
      onTap: () => showTimelineItemSheet(context, item),
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.xxs.value,
        children: [
          Text(
            appointmentDateText(s, appointmentAt, proximity),
            style: styles.heading2.copyWith(
              color: context.appColor(AppColors.primary),
            ),
          ),
          Text(timelineItemTitle(s, item), style: styles.bodyMedium),
          if (details.isNotEmpty)
            Text(
              details,
              style: styles.small.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
          Padding(
            padding: AppSpacing.xs.top,
            child: TimelineItemChips(item: item),
          ),
        ],
      ),
    );
  }
}
