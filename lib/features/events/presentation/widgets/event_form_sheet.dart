import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/use_cases/new_event_draft.dart';
import 'package:colette/features/events/presentation/providers/event_form_controller.dart';
import 'package:colette/features/events/presentation/widgets/bottle_field.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:colette/shared/ui/widgets/care_chip.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre le formulaire en bottom sheet. Renvoie `true` si un événement a été enregistré.
Future<bool?> showEventFormSheet(
  BuildContext context, {
  CareEvent? initial,
  CareType? preChecked,
  int? suggestedBottleMl,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => EventFormSheet(
    initial: initial,
    preChecked: preChecked,
    suggestedBottleMl: suggestedBottleMl,
  ),
);

/// Formulaire de création ou d'édition d'un événement.
class EventFormSheet extends ConsumerStatefulWidget {
  const EventFormSheet({
    super.key,
    this.initial,
    this.preChecked,
    this.suggestedBottleMl,
  });

  final CareEvent? initial;
  final CareType? preChecked;
  final int? suggestedBottleMl;

  @override
  ConsumerState<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends ConsumerState<EventFormSheet> {
  late CareEvent _draft;
  late final TextEditingController _noteController;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _draft =
        widget.initial ??
        newEventDraft(
          now: ref.read(clockProvider).now(),
          deviceId: ref.read(deviceIdProvider),
          id: ref.read(idGeneratorProvider).newId(),
          preChecked: widget.preChecked,
          bottleMl: widget.suggestedBottleMl,
        );
    _noteController = TextEditingController(text: _draft.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: isStart ? _draft.startAt : _draft.endAt,
      mode: CupertinoDatePickerMode.dateAndTime,
      minimum: isStart ? null : _draft.startAt,
    );
    if (picked == null) return;
    setState(() {
      _draft = isStart
          ? _draft.copyWith(
              startAt: picked,
              endAt: picked.isAfter(_draft.endAt) ? picked : _draft.endAt,
            )
          : _draft.copyWith(endAt: picked);
    });
  }

  Future<void> _save() async {
    final note = _noteController.text.trim();
    final saved = await ref
        .read(eventFormControllerProvider.notifier)
        .submit(_draft.copyWith(note: note.isEmpty ? null : note));
    if (saved != null && mounted) await Navigator.of(context).maybePop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    ref.listen(eventFormControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    final isLoading = ref.watch(eventFormControllerProvider) is AsyncLoading;
    final umbilicalEnabled =
        ref
            .watch(babyProfileProvider)
            .value
            ?.careSettings
            .umbilicalCareEnabled ??
        true;
    final visibleCares = CareType.values
        .where(
          (type) =>
              type != CareType.umbilicalCare ||
              umbilicalEnabled ||
              _draft.umbilicalCare,
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(
            _isEditing ? s.eventFormEditTitle : s.eventFormNewTitle,
            style: styles.heading2,
          ),
          AppSpacing.md.verticalSpace,
          Row(
            spacing: AppSpacing.sm.value,
            children: [
              Expanded(
                child: DateField(
                  label: s.fieldStartAt,
                  value: formatHourMinute(_draft.startAt),
                  onTap: () => _pickTime(isStart: true),
                ),
              ),
              Expanded(
                child: DateField(
                  label: s.fieldEndAt,
                  value: formatHourMinute(_draft.endAt),
                  onTap: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),
          AppSpacing.md.verticalSpace,
          Wrap(
            spacing: AppSpacing.sm.value,
            runSpacing: AppSpacing.sm.value,
            children: [
              for (final type in visibleCares)
                CareChip(
                  type: type,
                  selected: _draft.has(type),
                  onChanged: (value) =>
                      setState(() => _draft = _draft.toggle(type, value)),
                ),
            ],
          ),
          AppSpacing.md.verticalSpace,
          BottleField(
            bottleMl: _draft.bottleMl,
            onChanged: (ml) =>
                setState(() => _draft = _draft.copyWith(bottleMl: ml)),
          ),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: s.fieldNote,
              hintText: s.fieldNoteHint,
            ),
            minLines: 1,
            maxLines: 3,
            textCapitalization: .sentences,
          ),
          AppSpacing.lg.verticalSpace,
          FilledButton(
            onPressed: _draft.isEmpty || isLoading ? null : _save,
            child: Text(s.actionSave),
          ),
        ],
      ),
    );
  }
}
