import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/dates/time_format.dart';
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
import 'package:go_router/go_router.dart';

/// Tuile « Rendez-vous » d'Aujourd'hui, toujours affichée, à emphase graduée.
class AppointmentCard extends ConsumerWidget {
  const AppointmentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(medicalTimelineProvider);
    final proximity = ref.watch(nextAppointmentProximityProvider);
    final today = ref.watch(todayProvider);
    final awaiting = timeline?.awaitingConfirmation.firstOrNull;
    final next = timeline?.nextAppointment;
    final _State state;
    if (timeline == null) {
      state = const _Loading();
    } else if ((awaiting, awaiting?.appointmentAt) case (
      final item?,
      final at?,
    )) {
      state = _Awaiting(item, at);
    } else if ((next, next?.appointmentAt, proximity) case (
      final item?,
      final at?,
      final p?,
    )) {
      state = _Upcoming(item, at, p, calendarDaysBetween(today, at.dateOnly));
    } else {
      state = const _None();
    }
    return Padding(
      padding: AppSpacing.md.top,
      child: ColetteCardSurface(
        backgroundColor: state.background,
        borderColor: state.border,
        onTap: () => context.go(AppRoutes.health),
        child: Row(
          spacing: AppSpacing.sm.value,
          children: [
            Icon(state.icon, color: context.appColor(state.accent)),
            Expanded(child: _Body(state: state)),
            Icon(
              Icons.chevron_right,
              color: context.appColor(
                state.isImminent ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// État d'affichage de la tuile.
sealed class _State {
  const _State();

  AppColors get background => AppColors.surface;
  AppColors get border => AppColors.border;
  AppColors get accent => AppColors.textSecondary;
  IconData get icon => Icons.event_outlined;
  bool get isImminent => false;
}

/// Frise en chargement : en-tête seul, sans affirmer l'absence de RDV.
class _Loading extends _State {
  const _Loading();
}

/// Aucun RDV passé à confirmer ni programmé.
class _None extends _State {
  const _None();

  @override
  IconData get icon => Icons.event_busy_outlined;
}

/// RDV passé, visite pas encore marquée comme faite.
class _Awaiting extends _State {
  const _Awaiting(this.item, this.appointmentAt);

  final MedicalTimelineItem item;
  final DateTime appointmentAt;

  @override
  AppColors get border => AppColors.warning;
  @override
  AppColors get accent => AppColors.warning;
  @override
  IconData get icon => Icons.event_busy_outlined;
}

/// Prochain RDV programmé, emphase selon sa proximité.
class _Upcoming extends _State {
  const _Upcoming(this.item, this.appointmentAt, this.proximity, this.days);

  final MedicalTimelineItem item;
  final DateTime appointmentAt;
  final AppointmentProximity proximity;
  final int days;

  @override
  bool get isImminent => switch (proximity) {
    AppointmentProximity.today || AppointmentProximity.tomorrow => true,
    AppointmentProximity.soon || AppointmentProximity.later => false,
  };

  @override
  AppColors get background =>
      isImminent ? AppColors.primaryContainer : AppColors.surface;

  @override
  AppColors get border => switch (proximity) {
    AppointmentProximity.today ||
    AppointmentProximity.tomorrow => AppColors.primaryContainer,
    AppointmentProximity.soon => AppColors.primary,
    AppointmentProximity.later => AppColors.border,
  };

  @override
  AppColors get accent => proximity == AppointmentProximity.later
      ? AppColors.textSecondary
      : AppColors.primary;
}

/// En-tête `overline` puis lignes selon l'état.
class _Body extends StatelessWidget {
  const _Body({required this.state});

  final _State state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = styles.small.copyWith(
      color: context.appColor(AppColors.textSecondary),
    );
    final header = switch (state) {
      _Loading() || _None() => s.dashboardAppointmentTitle,
      _Awaiting() => s.dashboardAppointmentAwaiting,
      _Upcoming(:final proximity, :final days) =>
        proximity == AppointmentProximity.soon
            ? s.dashboardAppointmentSoon(days)
            : s.dashboardAppointmentTitle,
    };
    final lines = switch (state) {
      _Loading() => const <Widget>[],
      _None() => [
        Text(
          s.healthNoAppointment,
          style: styles.body.copyWith(
            color: context.appColor(AppColors.textSecondary),
          ),
        ),
      ],
      _Awaiting(:final item, :final appointmentAt) => [
        Text(timelineItemTitle(s, item), style: styles.bodyMedium),
        Text(formatDayAndTime(appointmentAt), style: secondary),
      ],
      _Upcoming(:final item, :final appointmentAt, :final proximity) =>
        state.isImminent
            ? [
                Text(
                  appointmentDateText(s, appointmentAt, proximity),
                  style: styles.heading2.copyWith(
                    color: context.appColor(AppColors.primary),
                  ),
                ),
                Text(timelineItemTitle(s, item), style: styles.bodyMedium),
                if (item.practitioner case final name?)
                  Text(name, style: secondary),
              ]
            : [
                Text(timelineItemTitle(s, item), style: styles.bodyMedium),
                Text(
                  [
                    formatDayAndTime(appointmentAt),
                    ?item.practitioner,
                  ].join(' · '),
                  style: secondary,
                ),
              ],
    };
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.xxs.value,
      children: [
        Text(
          header,
          style: styles.overline.copyWith(
            color: context.appColor(state.accent),
          ),
        ),
        ...lines,
      ],
    );
  }
}
