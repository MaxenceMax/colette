import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/use_cases/classify_sleep_kind.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_form_controller.dart';
import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_form_fields.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre le formulaire du sommeil. Renvoie `true` après enregistrement ou suppression.
///
/// [pickEndOnOpen] ouvre directement le sélecteur de fin (« Réveil oublié »).
Future<bool?> showSleepFormSheet(
  BuildContext context, {
  SleepSession? initial,
  bool pickEndOnOpen = false,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      SleepFormSheet(initial: initial, pickEndOnOpen: pickEndOnOpen),
);

/// Formulaire de création ou d'édition d'un sommeil.
class SleepFormSheet extends ConsumerStatefulWidget {
  const SleepFormSheet({super.key, this.initial, this.pickEndOnOpen = false});

  final SleepSession? initial;

  /// Ouvre le sélecteur de fin dès l'affichage du formulaire.
  final bool pickEndOnOpen;

  @override
  ConsumerState<SleepFormSheet> createState() => _SleepFormSheetState();
}

class _SleepFormSheetState extends ConsumerState<SleepFormSheet> {
  /// Durée pré-remplie d'un nouveau sommeil.
  static const _defaultLength = Duration(hours: 1);

  late final String _id;
  late DateTime _startAt;
  DateTime? _endAt;
  late SleepKind _kind;
  bool _kindTouched = false;
  Failure? _error;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider).now();
    final initial = widget.initial;
    _id = initial?.id ?? ref.read(idGeneratorProvider).newId();
    _startAt = initial?.startAt ?? now.subtract(_defaultLength);
    _endAt = initial == null ? now : initial.endAt;
    _kind = initial?.kind ?? SleepKind.nap;
    _kindTouched = initial != null;
    if (widget.pickEndOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickEnd();
      });
    }
  }

  Future<void> _pickStart() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: _startAt,
      mode: CupertinoDatePickerMode.dateAndTime,
      maximum: _endAt ?? ref.read(clockProvider).now(),
    );
    if (picked == null) return;
    setState(() {
      _startAt = picked;
      _error = null;
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: _endAt ?? ref.read(clockProvider).now(),
      mode: CupertinoDatePickerMode.dateAndTime,
      minimum: _startAt,
      maximum: ref.read(clockProvider).now(),
    );
    if (picked == null) return;
    setState(() {
      _endAt = picked;
      _error = null;
    });
  }

  void _clearEnd() => setState(() {
    _endAt = null;
    _error = null;
  });

  void _selectKind(SleepKind kind) => setState(() {
    _kind = kind;
    _kindTouched = true;
    _error = null;
  });

  Future<void> _save(SleepKind kind) async {
    setState(() => _error = null);
    final now = ref.read(clockProvider).now();
    final initial = widget.initial;
    final draft = SleepSession(
      id: _id,
      startAt: _startAt,
      endAt: _endAt,
      kind: kind,
      createdByDeviceId:
          initial?.createdByDeviceId ?? ref.read(deviceIdProvider),
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
    );
    final saved = await ref
        .read(sleepFormControllerProvider.notifier)
        .save(draft);
    // `pop` et non `maybePop` : le PopScope rend encore `canPop: false` tant
    // que le widget n'a pas été reconstruit après la fin de l'écriture.
    if (saved != null && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.deleteSleepTitle),
        content: Text(s.deleteEventBody),
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
    final deleted = await ref
        .read(sleepFormControllerProvider.notifier)
        .delete(widget.initial!.id);
    if (deleted && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    ref.listen(sleepFormControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        setState(() => _error = error is Failure ? error : null);
      }
    });
    final controller = ref.watch(sleepFormControllerProvider);
    final isLoading = controller is AsyncLoading;
    final settings =
        ref.watch(babyProfileProvider).value?.careSettings ??
        const CareSettings();
    final displayedKind = _kindTouched
        ? _kind
        : classifySleepKind(
            _startAt,
            nightStartHour: settings.nightStartHour,
            nightEndHour: settings.nightEndHour,
          );
    final now = ref.watch(clockProvider).now();
    return PopScope(
      canPop: !isLoading,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: AppSpacing.lg.all,
          children: [
            Text(
              _isEditing ? s.sleepFormEditTitle : s.sleepFormNewTitle,
              style: styles.heading2,
            ),
            AppSpacing.md.verticalSpace,
            SleepDatesSection(
              startAt: _startAt,
              endAt: _endAt,
              now: now,
              onPickStart: _pickStart,
              onPickEnd: _pickEnd,
            ),
            if (widget.initial?.isOngoing == true && _endAt != null) ...[
              AppSpacing.xs.verticalSpace,
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _clearEnd,
                  child: Text(s.sleepStillOngoing),
                ),
              ),
            ],
            AppSpacing.md.verticalSpace,
            SegmentedButton<SleepKind>(
              segments: [
                for (final kind in SleepKind.values)
                  ButtonSegment(value: kind, label: Text(kind.label(s))),
              ],
              selected: {displayedKind},
              onSelectionChanged: (selection) => _selectKind(selection.single),
            ),
            if (_error case final error?) ...[
              AppSpacing.md.verticalSpace,
              Semantics(
                liveRegion: true,
                child: Text(
                  failureMessage(error, s),
                  style: styles.small.copyWith(
                    color: context.appColor(AppColors.error),
                  ),
                ),
              ),
            ],
            AppSpacing.lg.verticalSpace,
            SleepActionsSection(
              isEditing: _isEditing,
              isLoading: isLoading,
              onSave: () => _save(displayedKind),
              onDelete: _delete,
            ),
          ],
        ),
      ),
    );
  }
}
