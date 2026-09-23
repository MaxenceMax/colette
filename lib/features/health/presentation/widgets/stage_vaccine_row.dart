import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/presentation/widgets/health_labels.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Un vaccin attendu : case à cocher puis date, nom commercial et lot.
class StageVaccineRow extends StatefulWidget {
  const StageVaccineRow({
    super.key,
    required this.vaccine,
    required this.given,
    required this.defaultDate,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
  });

  final ScheduledVaccine vaccine;
  final GivenVaccine? given;

  /// Date proposée à la coche (visite, sinon RDV, sinon aujourd'hui).
  final DateTime defaultDate;
  final DateTime minimum;
  final DateTime maximum;
  final ValueChanged<GivenVaccine?> onChanged;

  @override
  State<StageVaccineRow> createState() => _StageVaccineRowState();
}

class _StageVaccineRowState extends State<StageVaccineRow> {
  late final _brand = TextEditingController(text: widget.given?.brand ?? '');
  late final _lot = TextEditingController(text: widget.given?.lot ?? '');

  @override
  void dispose() {
    _brand.dispose();
    _lot.dispose();
    super.dispose();
  }

  static String? _clean(String text) =>
      text.trim().isEmpty ? null : text.trim();

  void _emit({DateTime? givenAt}) => widget.onChanged(
    GivenVaccine(
      givenAt: givenAt ?? widget.given?.givenAt ?? widget.defaultDate,
      brand: _clean(_brand.text),
      lot: _clean(_lot.text),
    ),
  );

  Future<void> _pickDate() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: widget.given?.givenAt ?? widget.defaultDate,
      mode: CupertinoDatePickerMode.date,
      minimum: widget.minimum,
      maximum: widget.maximum,
    );
    if (picked != null) _emit(givenAt: picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final given = widget.given;
    final name = HealthLabels.vaccine(s, widget.vaccine.code);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: given != null,
          title: Text(
            widget.vaccine.recommended
                ? '$name · ${s.healthSheetRecommended}'
                : name,
            style: Theme.of(context).coletteTextStyles.body,
          ),
          onChanged: (checked) =>
              checked ?? false ? _emit() : widget.onChanged(null),
        ),
        if (given != null)
          Padding(
            padding: AppSpacing.md.left,
            child: Column(
              crossAxisAlignment: .stretch,
              spacing: AppSpacing.sm.value,
              children: [
                DateField(
                  label: s.healthSheetGivenOn,
                  value: formatShortDate(given.givenAt),
                  onTap: _pickDate,
                ),
                TextField(
                  controller: _brand,
                  decoration: InputDecoration(labelText: s.healthSheetBrand),
                  onChanged: (_) => _emit(),
                ),
                TextField(
                  controller: _lot,
                  decoration: InputDecoration(labelText: s.healthSheetLot),
                  onChanged: (_) => _emit(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
