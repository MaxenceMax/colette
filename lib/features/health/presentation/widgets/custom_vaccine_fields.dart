import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/features/health/domain/entities/custom_vaccine.dart';
import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:colette/features/health/presentation/widgets/stage_vaccine_row.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Vaccins d'un RDV libre : les vaccins connus à cocher, puis les vaccins à
/// nom libre (ajout et retrait).
class CustomVaccineFields extends StatelessWidget {
  const CustomVaccineFields({
    super.key,
    required this.vaccines,
    required this.defaultDate,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
  });

  final List<CustomVaccine> vaccines;
  final DateTime defaultDate;
  final DateTime minimum;
  final DateTime maximum;
  final ValueChanged<List<CustomVaccine>> onChanged;

  CustomVaccine? _known(VaccineCode code) =>
      vaccines.where((v) => v.code == code).firstOrNull;

  void _setKnown(VaccineCode code, GivenVaccine? given) => onChanged([
    for (final v in vaccines)
      if (v.code != code) v,
    if (given != null)
      CustomVaccine(
        code: code,
        givenAt: given.givenAt,
        brand: given.brand,
        lot: given.lot,
      ),
  ]);

  void _setOther(int index, CustomVaccine? updated) {
    final others = vaccines.where((v) => v.code == null).toList();
    if (updated == null) {
      others.removeAt(index);
    } else {
      others[index] = updated;
    }
    onChanged([...vaccines.where((v) => v.code != null), ...others]);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final others = vaccines.where((v) => v.code == null).toList();
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final code in VaccineCode.values)
          StageVaccineRow(
            key: ValueKey(code),
            vaccine: ScheduledVaccine(code),
            given: switch (_known(code)) {
              final v? => GivenVaccine(
                givenAt: v.givenAt,
                brand: v.brand,
                lot: v.lot,
              ),
              null => null,
            },
            defaultDate: defaultDate,
            minimum: minimum,
            maximum: maximum,
            onChanged: (given) => _setKnown(code, given),
          ),
        for (final (index, other) in others.indexed)
          _OtherVaccineRow(
            key: ValueKey('other-$index'),
            vaccine: other,
            minimum: minimum,
            maximum: maximum,
            onChanged: (updated) => _setOther(index, updated),
          ),
        Align(
          alignment: .centerLeft,
          child: TextButton.icon(
            onPressed: () => onChanged([
              ...vaccines,
              CustomVaccine(name: '', givenAt: defaultDate),
            ]),
            icon: const Icon(Icons.add),
            label: Text(s.healthSheetAddOtherVaccine),
          ),
        ),
      ],
    );
  }
}

/// Vaccin à nom libre : nom, date, nom commercial, lot, bouton retirer.
class _OtherVaccineRow extends StatefulWidget {
  const _OtherVaccineRow({
    super.key,
    required this.vaccine,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
  });

  final CustomVaccine vaccine;
  final DateTime minimum;
  final DateTime maximum;

  /// `null` : retirer la ligne.
  final ValueChanged<CustomVaccine?> onChanged;

  @override
  State<_OtherVaccineRow> createState() => _OtherVaccineRowState();
}

class _OtherVaccineRowState extends State<_OtherVaccineRow> {
  late final _name = TextEditingController(text: widget.vaccine.name ?? '');
  late final _brand = TextEditingController(text: widget.vaccine.brand ?? '');
  late final _lot = TextEditingController(text: widget.vaccine.lot ?? '');

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _lot.dispose();
    super.dispose();
  }

  void _emit({DateTime? givenAt}) => widget.onChanged(
    widget.vaccine.copyWith(
      name: _name.text,
      brand: _brand.text,
      lot: _lot.text,
      givenAt: givenAt ?? widget.vaccine.givenAt,
    ),
  );

  Future<void> _pickDate() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: widget.vaccine.givenAt,
      mode: CupertinoDatePickerMode.date,
      minimum: widget.minimum,
      maximum: widget.maximum,
    );
    if (picked != null) _emit(givenAt: picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: AppSpacing.sm.vertical,
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.sm.value,
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: s.healthSheetVaccineName),
            textCapitalization: .sentences,
            onChanged: (_) => _emit(),
          ),
          DateField(
            label: s.healthSheetGivenOn,
            value: formatShortDate(widget.vaccine.givenAt),
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
          Align(
            alignment: .centerLeft,
            child: TextButton.icon(
              onPressed: () => widget.onChanged(null),
              icon: const Icon(Icons.remove_circle_outline),
              label: Text(s.healthSheetRemoveVaccine),
            ),
          ),
        ],
      ),
    );
  }
}
