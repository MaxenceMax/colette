import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:colette/features/health/domain/use_cases/reconcile_calendar.dart';
import 'package:colette/features/health/presentation/providers/medical_visit_controller.dart';
import 'package:colette/features/health/presentation/widgets/health_labels.dart';
import 'package:colette/features/health/presentation/widgets/stage_appointment_fields.dart';
import 'package:colette/features/health/presentation/widgets/stage_vaccine_row.dart';
import 'package:colette/features/health/presentation/widgets/stage_visit_fields.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la feuille de l'étape [entry].
Future<void> showMedicalStageSheet(
  BuildContext context,
  MedicalTimelineEntry entry,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => MedicalStageSheet(entry: entry),
);

/// Feuille d'une étape : RDV, vaccins attendus, visite faite.
class MedicalStageSheet extends ConsumerStatefulWidget {
  const MedicalStageSheet({super.key, required this.entry});

  final MedicalTimelineEntry entry;

  @override
  ConsumerState<MedicalStageSheet> createState() => _MedicalStageSheetState();
}

class _MedicalStageSheetState extends ConsumerState<MedicalStageSheet> {
  late final _practitioner = TextEditingController(
    text: widget.entry.visit?.practitioner ?? '',
  );
  late final _note = TextEditingController(
    text: widget.entry.visit?.note ?? '',
  );
  late DateTime? _appointmentAt = widget.entry.visit?.appointmentAt;
  late DateTime? _doneAt = widget.entry.visit?.doneAt;
  late Map<VaccineCode, GivenVaccine> _vaccines = {
    ...?widget.entry.visit?.vaccines,
  };

  @override
  void dispose() {
    _practitioner.dispose();
    _note.dispose();
    super.dispose();
  }

  static String? _clean(String text) =>
      text.trim().isEmpty ? null : text.trim();

  Future<void> _save(DateTime birthDate) async {
    final now = ref.read(clockProvider).now();
    final visit = MedicalVisit(
      stageId: widget.entry.stage.id,
      appointmentAt: _appointmentAt,
      practitioner: _appointmentAt == null ? null : _clean(_practitioner.text),
      doneAt: _doneAt,
      note: _clean(_note.text),
      vaccines: _vaccines,
      updatedAt: now,
      updatedByDeviceId: '',
    );
    final ok = await ref
        .read(medicalVisitControllerProvider.notifier)
        .save(visit, birthDate: birthDate);
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final stage = widget.entry.stage;
    final birthDate = ref.watch(babyProfileProvider).value?.birthDate;
    final isSaving = ref.watch(medicalVisitControllerProvider) is AsyncLoading;
    final now = ref.watch(clockProvider).now();
    final minimum = birthDate ?? widget.entry.dueFrom;
    final defaultDate = _doneAt ?? _appointmentAt ?? now;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        key: const Key('medicalStageSheetList'),
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(
            HealthLabels.stage(s, stage.id),
            style: Theme.of(context).coletteTextStyles.heading2,
          ),
          SectionHeader(title: s.healthSheetAppointment),
          StageAppointmentFields(
            appointmentAt: _appointmentAt,
            practitioner: _practitioner,
            minimum: minimum,
            maximum: ReconcileCalendar.windowEnd(now),
            initialPick: widget.entry.dueFrom.isAfter(now)
                ? widget.entry.dueFrom
                : now,
            onChanged: (value) => setState(() => _appointmentAt = value),
          ),
          if (stage.hasVaccines) ...[
            SectionHeader(title: s.healthSheetVaccines),
            for (final vaccine in stage.vaccines)
              StageVaccineRow(
                key: ValueKey(vaccine.code),
                vaccine: vaccine,
                given: _vaccines[vaccine.code],
                defaultDate: defaultDate.isAfter(now) ? now : defaultDate,
                minimum: minimum,
                maximum: now,
                onChanged: (given) => setState(
                  () => _vaccines = {
                    for (final e in _vaccines.entries)
                      if (e.key != vaccine.code) e.key: e.value,
                    vaccine.code: ?given,
                  },
                ),
              ),
          ],
          SectionHeader(title: s.healthSheetVisit),
          StageVisitFields(
            doneAt: _doneAt,
            note: _note,
            defaultDate: defaultDate.isAfter(now) ? now : defaultDate,
            minimum: minimum,
            maximum: now,
            onDoneChanged: (value) => setState(() => _doneAt = value),
          ),
          AppSpacing.lg.verticalSpace,
          FilledButton(
            onPressed: isSaving || birthDate == null
                ? null
                : () => _save(birthDate),
            child: Text(s.actionSave),
          ),
        ],
      ),
    );
  }
}
