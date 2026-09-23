import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:colette/features/health/domain/entities/custom_vaccine.dart';
import 'package:colette/features/health/domain/use_cases/reconcile_calendar.dart';
import 'package:colette/features/health/presentation/providers/custom_appointment_controller.dart';
import 'package:colette/features/health/presentation/widgets/custom_vaccine_fields.dart';
import 'package:colette/features/health/presentation/widgets/stage_visit_fields.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la feuille d'un RDV libre ; [initial] `null` pour en créer un.
Future<void> showCustomAppointmentSheet(
  BuildContext context, {
  CustomAppointment? initial,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => CustomAppointmentSheet(initial: initial),
);

/// Feuille d'un RDV libre : titre, date, praticien, vaccins, visite faite.
class CustomAppointmentSheet extends ConsumerStatefulWidget {
  const CustomAppointmentSheet({super.key, this.initial});

  final CustomAppointment? initial;

  @override
  ConsumerState<CustomAppointmentSheet> createState() =>
      _CustomAppointmentSheetState();
}

class _CustomAppointmentSheetState
    extends ConsumerState<CustomAppointmentSheet> {
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _practitioner = TextEditingController(
    text: widget.initial?.practitioner ?? '',
  );
  late final _note = TextEditingController(text: widget.initial?.note ?? '');
  late DateTime? _appointmentAt = widget.initial?.appointmentAt;
  late DateTime? _doneAt = widget.initial?.doneAt;
  late List<CustomVaccine> _vaccines = [...?widget.initial?.vaccines];
  final _titleFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Une seule demande de focus à la création : `autofocus` sur le champ
    // relancerait le clavier à chaque reconstruction du champ par la liste.
    if (widget.initial == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _titleFocus.dispose();
    _title.dispose();
    _practitioner.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Prochaine heure pleine : proposition par défaut pour un nouveau RDV.
  static DateTime _nextHour(DateTime now) =>
      DateTime(now.year, now.month, now.day, now.hour + 1);

  Future<void> _pickAppointment(DateTime minimum, DateTime now) async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: _appointmentAt ?? _nextHour(now),
      mode: CupertinoDatePickerMode.dateAndTime,
      minimum: minimum,
      maximum: ReconcileCalendar.windowEnd(now),
    );
    if (picked != null) setState(() => _appointmentAt = picked);
  }

  Future<void> _save(DateTime birthDate, DateTime now) async {
    final appointment = CustomAppointment(
      id: widget.initial?.id ?? ref.read(idGeneratorProvider).newId(),
      title: _title.text,
      appointmentAt: _appointmentAt ?? _nextHour(now),
      practitioner: _practitioner.text,
      doneAt: _doneAt,
      note: _note.text,
      vaccines: _vaccines,
      updatedAt: now,
      updatedByDeviceId: '',
    );
    final ok = await ref
        .read(customAppointmentControllerProvider.notifier)
        .save(appointment, birthDate: birthDate);
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  Future<void> _delete(String id) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.healthDeleteAppointmentTitle),
        content: Text(s.healthDeleteAppointmentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref
        .read(customAppointmentControllerProvider.notifier)
        .delete(id);
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final initial = widget.initial;
    final birthDate = ref.watch(babyProfileProvider).value?.birthDate;
    final isSaving =
        ref.watch(customAppointmentControllerProvider) is AsyncLoading;
    final now = ref.watch(clockProvider).now();
    final minimum = birthDate ?? now;
    final appointmentAt = _appointmentAt;
    final proposed =
        _doneAt ??
        (appointmentAt != null && appointmentAt.isBefore(now)
            ? appointmentAt
            : now);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        key: const Key('customAppointmentSheetList'),
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(
            initial?.title ?? s.healthNewAppointment,
            style: Theme.of(context).coletteTextStyles.heading2,
          ),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _title,
            focusNode: _titleFocus,
            decoration: InputDecoration(labelText: s.healthSheetTitle),
            textCapitalization: .sentences,
          ),
          SectionHeader(title: s.healthSheetAppointment),
          DateField(
            label: s.healthSheetAppointment,
            value: appointmentAt == null
                ? s.healthSheetPickAppointment
                : formatDayAndTime(appointmentAt),
            onTap: () => _pickAppointment(minimum, now),
          ),
          AppSpacing.sm.verticalSpace,
          TextField(
            controller: _practitioner,
            decoration: InputDecoration(labelText: s.healthSheetPractitioner),
            textCapitalization: .words,
          ),
          SectionHeader(title: s.healthSheetVaccines),
          CustomVaccineFields(
            vaccines: _vaccines,
            defaultDate: proposed,
            minimum: minimum,
            maximum: now,
            onChanged: (vaccines) => setState(() => _vaccines = vaccines),
          ),
          SectionHeader(title: s.healthSheetVisit),
          StageVisitFields(
            doneAt: _doneAt,
            note: _note,
            defaultDate: proposed,
            minimum: minimum,
            maximum: now,
            onDoneChanged: (value) => setState(() => _doneAt = value),
          ),
          AppSpacing.lg.verticalSpace,
          FilledButton(
            onPressed: isSaving || birthDate == null
                ? null
                : () => _save(birthDate, now),
            child: Text(s.actionSave),
          ),
          if (initial != null)
            TextButton(
              onPressed: isSaving ? null : () => _delete(initial.id),
              style: TextButton.styleFrom(
                foregroundColor: context.appColor(AppColors.error),
              ),
              child: Text(s.actionDelete),
            ),
        ],
      ),
    );
  }
}
