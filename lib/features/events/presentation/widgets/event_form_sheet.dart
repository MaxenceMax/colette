import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/use_cases/bottle_timer.dart';
import 'package:colette/features/events/domain/use_cases/new_event_draft.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_controller.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_session_providers.dart';
import 'package:colette/features/events/presentation/providers/event_form_controller.dart';
import 'package:colette/features/events/presentation/widgets/bottle_field.dart';
import 'package:colette/features/events/presentation/widgets/bottle_timer_stop_dialog.dart';
import 'package:colette/features/events/presentation/widgets/event_form_header.dart';
import 'package:colette/features/events/presentation/widgets/event_time_fields.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:colette/shared/ui/widgets/care_chip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre le formulaire en bottom sheet. Renvoie `true` si un événement a été enregistré.
Future<bool?> showEventFormSheet(
  BuildContext context, {
  CareEvent? initial,
  CareType? preChecked,
  int? suggestedBottleMl,
  BottleTimerSession? restored,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  // Le glisser appelle `Navigator.pop` et contourne le `PopScope` qui
  // confirme l'arrêt du minuteur de biberon.
  enableDrag: false,
  builder: (_) => EventFormSheet(
    initial: initial,
    preChecked: preChecked,
    suggestedBottleMl: suggestedBottleMl,
    restored: restored,
  ),
);

/// Formulaire de création ou d'édition d'un événement.
class EventFormSheet extends ConsumerStatefulWidget {
  const EventFormSheet({
    super.key,
    this.initial,
    this.preChecked,
    this.suggestedBottleMl,
    this.restored,
  });

  final CareEvent? initial;
  final CareType? preChecked;
  final int? suggestedBottleMl;

  /// Minuteur interrompu (app tuée) à reprendre avec son brouillon.
  final BottleTimerSession? restored;

  @override
  ConsumerState<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends ConsumerState<EventFormSheet> {
  late CareEvent _draft;
  late final TextEditingController _noteController;

  /// Posé au `pop` : la feuille reste montée pendant l'animation de fermeture.
  bool _closing = false;

  bool get _isEditing =>
      widget.initial != null || (widget.restored?.editing ?? false);

  @override
  void initState() {
    super.initState();
    final restored = widget.restored;
    _draft =
        restored?.draft ??
        widget.initial ??
        newEventDraft(
          now: ref.read(clockProvider).now(),
          deviceId: ref.read(deviceIdProvider),
          id: ref.read(idGeneratorProvider).newId(),
          preChecked: widget.preChecked,
          bottleMl: widget.suggestedBottleMl,
        );
    _noteController = TextEditingController(text: _draft.note ?? '')
      ..addListener(_persistSession);
    if (restored != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _resume(restored.run),
      );
    }
  }

  /// Reprend le minuteur ; s'il a fini pendant que l'app était tuée,
  /// enregistre sans son (les notifications ont déjà sonné).
  void _resume(BottleTimerRun run) {
    if (!mounted) return;
    ref.read(bottleTimerControllerProvider.notifier).restore(run);
    final now = ref.read(clockProvider).now();
    if (computeBottleTimerPhase(run: run, now: now) is BottleTimerDone) {
      _autoSave();
    }
  }

  void _setDraft(CareEvent draft) {
    setState(() => _draft = draft);
    _persistSession();
  }

  /// Sauvegarde minuteur et brouillon tant que le minuteur tourne.
  void _persistSession() {
    final run = ref.read(bottleTimerControllerProvider);
    if (run == null) return;
    final note = _noteController.text.trim();
    final draft = _draft.copyWith(note: note.isEmpty ? null : note);
    final session = BottleTimerSession(
      run: run,
      draft: draft,
      editing: _isEditing,
    );
    unawaited(ref.read(bottleTimerSessionRepositoryProvider).save(session));
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
      maximum: isStart ? ref.read(clockProvider).now() : null,
    );
    if (picked == null) return;
    _setDraft(
      isStart
          ? _draft.copyWith(
              startAt: picked,
              endAt: picked.isAfter(_draft.endAt) ? picked : _draft.endAt,
            )
          : _draft.copyWith(endAt: picked),
    );
  }

  Future<void> _save() async {
    final note = _noteController.text.trim();
    final saved = await ref
        .read(eventFormControllerProvider.notifier)
        .submit(_draft.copyWith(note: note.isEmpty ? null : note));
    // `pop` et non `maybePop` : enregistrer ferme même si le minuteur tourne.
    if (saved != null && mounted) {
      _closing = true;
      Navigator.of(context).pop(true);
    }
  }

  /// Fin du minuteur : enregistre le soin aux heures du minuteur.
  Future<void> _autoSave() async {
    final run = ref.read(bottleTimerControllerProvider);
    if (_closing ||
        run == null ||
        ref.read(eventFormControllerProvider) is AsyncLoading) {
      return;
    }
    setState(
      () => _draft = _draft.copyWith(
        startAt: run.startedAt,
        endAt: run.feedingEndsAt,
      ),
    );
    await _save();
  }

  Future<void> _confirmClose() async {
    if (!await confirmBottleTimerStop(context) || !mounted) return;
    ref.read(bottleTimerControllerProvider.notifier).reset();
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    ref.listen(eventFormControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    final isLoading = ref.watch(eventFormControllerProvider) is AsyncLoading;
    ref
      ..watch(bottleTimerEffectsProvider)
      ..listen(bottleTimerPhaseProvider, (previous, next) {
        if (bottleTimerTransition(previous, next) == .finished) _autoSave();
      })
      ..listen(bottleTimerControllerProvider, (_, run) {
        if (run != null) _persistSession();
      });
    final timerPhase = ref.watch(bottleTimerPhaseProvider);
    final timerRunning =
        timerPhase is BottleFeeding || timerPhase is BottleUpright;
    final umbilicalEnabled =
        ref
            .watch(babyProfileProvider)
            .value
            ?.careSettings
            .umbilicalCare
            .enabled ??
        true;
    final visibleCares = CareType.values
        .where(
          (type) =>
              type != CareType.umbilicalCare ||
              umbilicalEnabled ||
              _draft.umbilicalCare,
        )
        .toList();

    return PopScope(
      canPop: !timerRunning && !isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && timerRunning) _confirmClose();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: AppSpacing.lg.all,
          children: [
            EventFormHeader(isEditing: _isEditing),
            AppSpacing.md.verticalSpace,
            EventTimeFields(
              startAt: _draft.startAt,
              endAt: _draft.endAt,
              onPickStart: () => _pickTime(isStart: true),
              onPickEnd: () => _pickTime(isStart: false),
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
                    onChanged: (value) => _setDraft(_draft.toggle(type, value)),
                  ),
              ],
            ),
            AppSpacing.md.verticalSpace,
            BottleField(
              bottleMl: _draft.bottleMl,
              onChanged: (ml) {
                if (ml == null) {
                  ref.read(bottleTimerControllerProvider.notifier).reset();
                }
                _setDraft(_draft.copyWith(bottleMl: ml));
              },
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
      ),
    );
  }
}
