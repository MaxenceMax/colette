import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/presentation/widgets/sheet_failure_text.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_controller.dart';
import 'package:colette/features/teeth/presentation/teeth_ui.dart';
import 'package:colette/features/teeth/presentation/widgets/optional_date_field.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la fiche de [toothId] ; [initial] `null` si rien n'est noté.
Future<void> showToothSheet(
  BuildContext context, {
  required ToothId toothId,
  ToothRecord? initial,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => ToothSheet(toothId: toothId, initial: initial),
);

/// Fiche d'une dent : repère d'âge, sortie, chute (dent de lait), note.
class ToothSheet extends ConsumerStatefulWidget {
  const ToothSheet({super.key, required this.toothId, this.initial});

  final ToothId toothId;
  final ToothRecord? initial;

  @override
  ConsumerState<ToothSheet> createState() => _ToothSheetState();
}

class _ToothSheetState extends ConsumerState<ToothSheet> {
  late final _note = TextEditingController(text: widget.initial?.note ?? '');
  late DateTime? _eruptedAt = widget.initial?.eruptedAt;
  late DateTime? _lostAt = widget.initial?.lostAt;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(DateTime birthDate, DateTime now) async {
    final record = ToothRecord(
      toothId: widget.toothId,
      eruptedAt: _eruptedAt,
      lostAt: _lostAt,
      note: _note.text,
      updatedAt: now,
      updatedByDeviceId: '',
    );
    final ok = await ref
        .read(teethControllerProvider.notifier)
        .save(record, birthDate: birthDate);
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  Future<void> _clear() async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.toothClearTitle),
        content: Text(s.toothClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.toothClear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref
        .read(teethControllerProvider.notifier)
        .clear(widget.toothId);
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final id = widget.toothId;
    final birthDate = ref.watch(babyProfileProvider).value?.birthDate;
    final saveState = ref.watch(teethControllerProvider);
    final isSaving = saveState is AsyncLoading;
    final now = ref.watch(clockProvider).now();
    final today = DateTime(now.year, now.month, now.day, 12);
    final minimum = birthDate ?? now;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(toothName(id, s), style: styles.heading2),
          Text(
            s.toothNumber(id.value),
            style: styles.small.copyWith(color: secondary),
          ),
          AppSpacing.sm.verticalSpace,
          Text(
            toothReferenceText(id, s),
            style: styles.body.copyWith(color: secondary),
          ),
          AppSpacing.lg.verticalSpace,
          OptionalDateField(
            label: s.toothEruptedAt,
            addLabel: s.toothAddEruption,
            removeLabel: s.toothRemoveEruption,
            value: _eruptedAt,
            defaultDate: today,
            minimum: minimum,
            maximum: _lostAt ?? now,
            onChanged: (value) => setState(() => _eruptedAt = value),
          ),
          if (id.dentition == Dentition.primary) ...[
            AppSpacing.md.verticalSpace,
            OptionalDateField(
              label: s.toothLostAt,
              addLabel: s.toothAddLoss,
              removeLabel: s.toothRemoveLoss,
              value: _lostAt,
              defaultDate: today,
              minimum: _eruptedAt ?? minimum,
              maximum: now,
              onChanged: (value) => setState(() => _lostAt = value),
            ),
          ],
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: s.toothNote),
            maxLines: null,
            textCapitalization: .sentences,
          ),
          if (saveState case AsyncError(:final error))
            SheetFailureText(failure: error),
          AppSpacing.lg.verticalSpace,
          FilledButton(
            onPressed: isSaving || birthDate == null
                ? null
                : () => _save(birthDate, now),
            child: Text(s.actionSave),
          ),
          if (widget.initial != null)
            TextButton(
              onPressed: isSaving ? null : _clear,
              style: TextButton.styleFrom(
                foregroundColor: context.appColor(AppColors.error),
              ),
              child: Text(s.toothClear),
            ),
        ],
      ),
    );
  }
}
