import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/baby/presentation/widgets/growth_format.dart';
import 'package:colette/features/baby/presentation/widgets/growth_input.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Ouvre la saisie d'une mesure ; [initial] ouvre la modification de cette mesure.
Future<void> showGrowthMeasurementSheet(
  BuildContext context, {
  GrowthMeasurement? initial,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => GrowthMeasurementSheet(initial: initial),
);

/// Date (de la naissance à aujourd'hui), poids, taille et périmètre crânien,
/// chacun facultatif mais au moins un renseigné.
class GrowthMeasurementSheet extends ConsumerStatefulWidget {
  const GrowthMeasurementSheet({super.key, this.initial});

  /// Mesure modifiée, ou `null` pour une nouvelle mesure.
  final GrowthMeasurement? initial;

  @override
  ConsumerState<GrowthMeasurementSheet> createState() =>
      _GrowthMeasurementSheetState();
}

class _GrowthMeasurementSheetState
    extends ConsumerState<GrowthMeasurementSheet> {
  late final _gramsController = TextEditingController(
    text: widget.initial?.grams?.toString() ?? '',
  );
  late final _lengthController = TextEditingController(
    text: _centimetres(widget.initial?.lengthMm),
  );
  late final _headController = TextEditingController(
    text: _centimetres(widget.initial?.headCircumferenceMm),
  );
  late final _fields = Listenable.merge([
    _gramsController,
    _lengthController,
    _headController,
  ]);
  late DateTime _measuredAt =
      widget.initial?.measuredAt ?? ref.read(clockProvider).now().dateOnly;

  static String _centimetres(int? mm) =>
      mm == null ? '' : GrowthFormat.centimetres(mm);

  bool get _allEmpty => [
    _gramsController,
    _lengthController,
    _headController,
  ].every((c) => c.text.trim().isEmpty);

  @override
  void dispose() {
    _gramsController.dispose();
    _lengthController.dispose();
    _headController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: _measuredAt,
      mode: CupertinoDatePickerMode.date,
      maximum: ref.read(clockProvider).now(),
      minimum: ref.read(babyProfileProvider).value?.birthDate,
    );
    if (picked != null) setState(() => _measuredAt = picked.dateOnly);
  }

  Future<void> _save() async {
    final ok = await ref
        .read(babySettingsControllerProvider.notifier)
        .saveMeasurement(
          id: widget.initial?.id,
          measuredAt: _measuredAt,
          grams: GrowthInput.grams(_gramsController.text),
          lengthMm: GrowthInput.millimetres(_lengthController.text),
          headCircumferenceMm: GrowthInput.millimetres(_headController.text),
        );
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Gardé à l'écoute : `_pickDate` y lit la date de naissance, borne basse.
    ref.watch(babyProfileProvider);
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(
            widget.initial == null
                ? s.actionAddMeasurement
                : s.editMeasurementTitle,
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
            autofocus: widget.initial == null,
          ),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _lengthController,
            decoration: InputDecoration(labelText: s.fieldLengthCm),
            keyboardType: decimal,
          ),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _headController,
            decoration: InputDecoration(labelText: s.fieldHeadCircumferenceCm),
            keyboardType: decimal,
          ),
          AppSpacing.lg.verticalSpace,
          ListenableBuilder(
            listenable: _fields,
            builder: (context, _) => FilledButton(
              onPressed: _allEmpty ? null : _save,
              child: Text(s.actionSave),
            ),
          ),
        ],
      ),
    );
  }
}
