import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/medical_visit_controller.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page Santé : étapes en retard, à faire, à venir et faites.
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
    // Garde le contrôleur autoDispose vivant pendant les écritures de la feuille.
    ref.listen(medicalVisitControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    final timeline = ref.watch(medicalTimelineProvider);
    final entries = timeline?.entries ?? const <MedicalTimelineEntry>[];
    List<MedicalTimelineEntry> where(Set<MedicalStageStatus> statuses) => [
      for (final e in entries)
        if (statuses.contains(e.status)) e,
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
      appBar: AppBar(title: Text(s.healthTitle)),
      body: ListView(
        padding: AppSpacing.md.horizontal,
        children: [
          const _CalendarStatus(),
          if (late.isNotEmpty)
            _Section(title: s.healthSectionLate, entries: late),
          if (toDo.isNotEmpty)
            _Section(title: s.healthSectionToDo, entries: toDo),
          if (upcoming.isNotEmpty)
            _Section(title: s.healthSectionUpcoming, entries: upcoming),
          if (done.isNotEmpty) _DoneSection(entries: done),
          AppSpacing.xl.verticalSpace,
        ],
      ),
    );
  }
}

/// Calendrier synchronisé sur cet iPhone, ou invitation à le régler.
class _CalendarStatus extends ConsumerWidget {
  const _CalendarStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final choice = ref.watch(selectedCalendarProvider);
    return Padding(
      padding: AppSpacing.md.vertical,
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          Icon(
            choice == null ? Icons.event_busy_outlined : Icons.event_available,
            color: context.appColor(AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              choice == null
                  ? s.healthCalendarNotConfigured
                  : s.healthCalendarSynced(choice.title),
              style: Theme.of(context).coletteTextStyles.small
                  .copyWith(color: context.appColor(AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.entries});

  final String title;
  final List<MedicalTimelineEntry> entries;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      SectionHeader(title: title),
      ColetteCardSurface(
        padding: AppSpacing.xs.all,
        child: Column(
          children: [
            for (final entry in entries)
              MedicalStageTile(
                entry: entry,
                onTap: () => showMedicalStageSheet(context, entry),
              ),
          ],
        ),
      ),
    ],
  );
}

/// Étapes faites, repliées par défaut.
class _DoneSection extends StatelessWidget {
  const _DoneSection({required this.entries});

  final List<MedicalTimelineEntry> entries;

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.md.top,
    child: ColetteCardSurface(
      padding: AppSpacing.xs.all,
      child: ExpansionTile(
        title: Text(
          S.of(context).healthSectionDone(entries.length),
          style: Theme.of(context).coletteTextStyles.bodyMedium,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          for (final entry in entries)
            MedicalStageTile(
              entry: entry,
              onTap: () => showMedicalStageSheet(context, entry),
            ),
        ],
      ),
    ),
  );
}

/// Remplacée par la feuille d'étape à la tâche 10.
Future<void> showMedicalStageSheet(
  BuildContext context,
  MedicalTimelineEntry entry,
) async {}
