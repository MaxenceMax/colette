import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/health/domain/entities/calendar_choice.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/providers/calendar_sync_issue.dart';
import 'package:colette/features/health/presentation/providers/custom_appointment_controller.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/medical_visit_controller.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/health/presentation/widgets/awaiting_confirmation_section.dart';
import 'package:colette/features/health/presentation/widgets/custom_appointment_sheet.dart';
import 'package:colette/features/health/presentation/widgets/custom_appointment_tile.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_tile.dart';
import 'package:colette/features/health/presentation/widgets/next_appointment_card.dart';
import 'package:colette/features/health/presentation/widgets/scheduled_section.dart';
import 'package:colette/features/health/presentation/widgets/timeline_item_ui.dart';
import 'package:colette/features/health/presentation/widgets/to_schedule_section.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page Santé : prochain RDV en évidence, autres RDV programmés, RDV passés
/// à confirmer, étapes à programmer, puis à venir et faites repliées.
class HealthPage extends ConsumerStatefulWidget {
  const HealthPage({super.key});

  @override
  ConsumerState<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends ConsumerState<HealthPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(healthSyncProvider).sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Garde les contrôleurs autoDispose vivants pendant les écritures des feuilles.
    void showError(AsyncValue<void> next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    }

    ref.listen(medicalVisitControllerProvider, (_, next) => showError(next));
    ref.listen(
      customAppointmentControllerProvider,
      (_, next) => showError(next),
    );
    final timeline = ref.watch(medicalTimelineProvider);
    final hasIssue = ref.watch(calendarSyncIssueProvider) != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.healthTitle),
        actions: [
          IconButton(
            tooltip: s.healthAddAppointment,
            icon: const Icon(Icons.add),
            onPressed: () => showCustomAppointmentSheet(context),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.md.horizontal,
        children: [
          if (hasIssue) const _CalendarStatus(),
          const NextAppointmentCard(),
          if (timeline != null) ...[
            ScheduledSection(items: timeline.scheduled),
            AwaitingConfirmationSection(items: timeline.awaitingConfirmation),
            ToScheduleSection(items: timeline.toSchedule),
            if (timeline.upcoming.isNotEmpty)
              _CollapsedSection(
                title: s.healthSectionUpcomingCount(timeline.upcoming.length),
                items: timeline.upcoming,
              ),
            if (timeline.done.isNotEmpty)
              _CollapsedSection(
                title: s.healthSectionDone(timeline.done.length),
                items: timeline.done,
              ),
          ],
          if (!hasIssue) const _CalendarStatus(),
          AppSpacing.xl.verticalSpace,
        ],
      ),
    );
  }
}

/// Alerte de synchronisation (en haut, `warning`) ou état du calendrier
/// (en pied de page, discret).
class _CalendarStatus extends ConsumerWidget {
  const _CalendarStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final choice = ref.watch(selectedCalendarProvider);
    final issue = ref.watch(calendarSyncIssueProvider);
    final (icon, text, color) = switch ((issue, choice)) {
      (final CalendarReason reason, _) => (
        Icons.sync_problem,
        failureMessage(CalendarFailure(reason), s),
        AppColors.warning,
      ),
      (null, null) => (
        Icons.event_busy_outlined,
        s.healthCalendarNotConfigured,
        AppColors.textSecondary,
      ),
      (null, final CalendarChoice choice) => (
        Icons.event_available,
        s.healthCalendarSynced(choice.title),
        AppColors.textSecondary,
      ),
    };
    return Padding(
      padding: AppSpacing.md.vertical,
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          Icon(icon, color: context.appColor(color)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).coletteTextStyles.small
                  .copyWith(color: context.appColor(color)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile d'un élément de la frise ; tap : feuille d'étape ou de RDV libre.
class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});

  final MedicalTimelineItem item;

  @override
  Widget build(BuildContext context) => switch (item) {
    StageItem(:final entry) => MedicalStageTile(
      entry: entry,
      onTap: () => showTimelineItemSheet(context, item),
    ),
    final AppointmentItem appointment => CustomAppointmentTile(
      item: appointment,
      onTap: () => showTimelineItemSheet(context, item),
    ),
  };
}

/// Section repliée par défaut : « À venir (n) », « Faites (n) ».
class _CollapsedSection extends StatelessWidget {
  const _CollapsedSection({required this.title, required this.items});

  final String title;
  final List<MedicalTimelineItem> items;

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.md.top,
    child: ColetteCardSurface(
      padding: AppSpacing.xs.all,
      child: ExpansionTile(
        title: Text(
          title,
          style: Theme.of(context).coletteTextStyles.bodyMedium,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        children: [for (final item in items) _ItemTile(item: item)],
      ),
    ),
  );
}
