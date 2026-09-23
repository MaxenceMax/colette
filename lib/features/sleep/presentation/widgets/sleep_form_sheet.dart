import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/ids/id_generator.dart';
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
import 'package:colette/features/sleep/presentation/providers/sleep_controller.dart';
import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre le formulaire du sommeil. Renvoie `true` après enregistrement ou suppression.
Future<bool?> showSleepFormSheet(
  BuildContext context, {
  SleepSession? initial,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => SleepFormSheet(initial: initial),
);

/// Formulaire de création ou d'édition d'un sommeil.
class SleepFormSheet extends ConsumerStatefulWidget {
  const SleepFormSheet({super.key, this.initial});

  final SleepSession? initial;

  @override
  ConsumerState<SleepFormSheet> createState() => _SleepFormSheetState();
}

class _SleepFormSheetState extends ConsumerState<SleepFormSheet> {
  /// Durée pré-remplie d'un nouveau sommeil.
  static const _defaultLength = Duration(hours: 1);

  late DateTime _startAt;
  DateTime? _endAt;
  late SleepKind _kind;
  bool _kindTouched = false;

  bool get _isEditing => widget.initial != null;

  CareSettings get _settings =>
      ref.read(babyProfileProvider).value?.careSettings ?? const CareSettings();

  SleepKind _classify(DateTime start) => classifySleepKind(
    start,
    nightStartHour: _settings.nightStartHour,
    nightEndHour: _settings.nightEndHour,
  );

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider).now();
    final initial = widget.initial;
    _startAt = initial?.startAt ?? now.subtract(_defaultLength);
    _endAt = initial == null ? now : initial.endAt;
    _kind = initial?.kind ?? _classify(_startAt);
    _kindTouched = initial != null;
  }

  Future<void> _pickStart() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: _startAt,
      mode: CupertinoDatePickerMode.dateAndTime,
      maximum: ref.read(clockProvider).now(),
    );
    if (picked == null) return;
    setState(() {
      _startAt = picked;
      if (!_kindTouched) _kind = _classify(picked);
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
    setState(() => _endAt = picked);
  }

  Future<void> _save() async {
    final now = ref.read(clockProvider).now();
    final initial = widget.initial;
    final draft = SleepSession(
      id: initial?.id ?? ref.read(idGeneratorProvider).newId(),
      startAt: _startAt,
      endAt: _endAt,
      kind: _kind,
      createdByDeviceId:
          initial?.createdByDeviceId ?? ref.read(deviceIdProvider),
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
    );
    final saved = await ref.read(sleepControllerProvider.notifier).save(draft);
    if (saved != null && mounted) await Navigator.of(context).maybePop(true);
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
        .read(sleepControllerProvider.notifier)
        .delete(widget.initial!.id);
    if (deleted && mounted) await Navigator.of(context).maybePop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final controller = ref.watch(sleepControllerProvider);
    final isLoading = controller is AsyncLoading;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(
            _isEditing ? s.sleepFormEditTitle : s.sleepFormNewTitle,
            style: styles.heading2,
          ),
          AppSpacing.md.verticalSpace,
          Row(
            spacing: AppSpacing.sm.value,
            children: [
              Expanded(
                child: DateField(
                  label: s.fieldStartAt,
                  value: formatHourMinute(_startAt),
                  onTap: _pickStart,
                ),
              ),
              Expanded(
                child: DateField(
                  label: s.fieldEndAt,
                  value: switch (_endAt) {
                    null => s.sleepOngoing,
                    final end => formatHourMinute(end),
                  },
                  onTap: _pickEnd,
                ),
              ),
            ],
          ),
          AppSpacing.md.verticalSpace,
          SegmentedButton<SleepKind>(
            segments: [
              for (final kind in SleepKind.values)
                ButtonSegment(value: kind, label: Text(kind.label(s))),
            ],
            selected: {_kind},
            onSelectionChanged: (selection) => setState(() {
              _kind = selection.single;
              _kindTouched = true;
            }),
          ),
          if (controller case AsyncError(:final error)) ...[
            AppSpacing.md.verticalSpace,
            Text(
              failureMessage(error, s),
              style: styles.small.copyWith(
                color: context.appColor(AppColors.error),
              ),
            ),
          ],
          AppSpacing.lg.verticalSpace,
          FilledButton(
            onPressed: isLoading ? null : _save,
            child: Text(s.actionSave),
          ),
          if (_isEditing) ...[
            AppSpacing.sm.verticalSpace,
            TextButton(
              onPressed: isLoading ? null : _delete,
              style: TextButton.styleFrom(
                foregroundColor: context.appColor(AppColors.error),
              ),
              child: Text(s.actionDelete),
            ),
          ],
        ],
      ),
    );
  }
}
