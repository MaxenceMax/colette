import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Ouvre la saisie d'une pesée.
Future<void> showAddWeightSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddWeightSheet(),
    );

/// Date + grammes.
class AddWeightSheet extends ConsumerStatefulWidget {
  const AddWeightSheet({super.key});

  @override
  ConsumerState<AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends ConsumerState<AddWeightSheet> {
  final _gramsController = TextEditingController();
  late DateTime _measuredAt = ref.read(clockProvider).now().dateOnly;

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: _measuredAt,
      mode: CupertinoDatePickerMode.date,
      maximum: ref.read(clockProvider).now(),
    );
    if (picked != null) setState(() => _measuredAt = picked.dateOnly);
  }

  Future<void> _save() async {
    final grams = int.tryParse(_gramsController.text.trim()) ?? 0;
    final ok = await ref
        .read(babySettingsControllerProvider.notifier)
        .addWeight(measuredAt: _measuredAt, grams: grams);
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(
            s.settingsAddWeight,
            style: Theme.of(context).coletteTextStyles.heading2,
          ),
          AppSpacing.md.verticalSpace,
          DateField(
            label: s.fieldMeasuredAt,
            value: DateFormat.yMMMMd('fr').format(_measuredAt),
            onTap: _pickDate,
          ),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _gramsController,
            decoration: InputDecoration(labelText: s.fieldWeightGrams),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          AppSpacing.lg.verticalSpace,
          FilledButton(onPressed: _save, child: Text(s.actionAdd)),
        ],
      ),
    );
  }
}
