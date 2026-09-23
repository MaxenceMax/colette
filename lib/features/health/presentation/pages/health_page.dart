import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/health/domain/entities/calendar_choice.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/providers/calendar_sync_issue.dart';
import 'package:colette/features/health/presentation/providers/custom_appointment_controller.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/medical_visit_controller.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/health/presentation/widgets/custom_appointment_sheet.dart';
import 'package:colette/features/health/presentation/widgets/custom_appointment_tile.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_sheet.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page Santé : étapes et RDV libres en retard, à faire, à venir et faits.
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
    final items = timeline?.items ?? const <MedicalTimelineItem>[];
    List<MedicalTimelineItem> where(Set<MedicalStageStatus> statuses) => [
      for (final i in items)
        if (statuses.contains(i.status)) i,
    ];
    final late = where({MedicalStageStatus.late});
    final toDo = where({
      MedicalStageStatus.appointmentPassed,
      MedicalStageStatus.scheduled,
      MedicalStageStatus.due,
    });
    final upcoming = where({MedicalStageStatus.upcoming});
    final done = where({MedicalStageStatus.done});
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
          const _CalendarStatus(),
          if (late.isNotEmpty)
            _Section(title: s.healthSectionLate, items: late),
          if (toDo.isNotEmpty)
            _Section(title: s.healthSectionToDo, items: toDo),
          if (upcoming.isNotEmpty)
            _Section(title: s.healthSectionUpcoming, items: upcoming),
          if (done.isNotEmpty) _DoneSection(items: done),
          AppSpacing.xl.verticalSpace,
        ],
      ),
    );
  }
}

/// Calendrier synchronisé sur cet iPhone, alerte de synchronisation, ou
/// invitation à le régler.
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
      onTap: () => showMedicalStageSheet(context, entry),
    ),
    AppointmentItem(:final appointment) && final it => CustomAppointmentTile(
      item: it,
      onTap: () => showCustomAppointmentSheet(context, initial: appointment),
    ),
  };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<MedicalTimelineItem> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      SectionHeader(title: title),
      ColetteCardSurface(
        padding: AppSpacing.xs.all,
        child: Column(
          children: [for (final item in items) _ItemTile(item: item)],
        ),
      ),
    ],
  );
}

/// Étapes faites, repliées par défaut.
class _DoneSection extends StatelessWidget {
  const _DoneSection({required this.items});

  final List<MedicalTimelineItem> items;

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.md.top,
    child: ColetteCardSurface(
      padding: AppSpacing.xs.all,
      child: ExpansionTile(
        title: Text(
          S.of(context).healthSectionDone(items.length),
          style: Theme.of(context).coletteTextStyles.bodyMedium,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        children: [for (final item in items) _ItemTile(item: item)],
      ),
    ),
  );
}
