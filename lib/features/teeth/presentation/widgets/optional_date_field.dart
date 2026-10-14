import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/material.dart';

/// Date facultative : bouton d'ajout, puis champ de date et bouton pour la retirer.
class OptionalDateField extends StatelessWidget {
  const OptionalDateField({
    super.key,
    required this.label,
    required this.addLabel,
    required this.value,
    required this.defaultDate,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
  });

  final String label;
  final String addLabel;
  final DateTime? value;

  /// Date proposée à l'ajout (aujourd'hui à midi).
  final DateTime defaultDate;
  final DateTime minimum;
  final DateTime maximum;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context, DateTime current) async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: current,
      mode: .date,
      minimum: minimum,
      maximum: maximum,
    );
    // Seul le jour compte : midi évite tout décalage lié à l'heure.
    if (picked != null) {
      onChanged(DateTime(picked.year, picked.month, picked.day, 12));
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = value;
    if (date == null) {
      return OutlinedButton.icon(
        onPressed: () => onChanged(defaultDate),
        icon: const Icon(Icons.add),
        label: Text(addLabel),
      );
    }
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.xs.value,
      children: [
        DateField(
          label: label,
          value: formatShortDate(date),
          onTap: () => _pick(context, date),
        ),
        TextButton.icon(
          onPressed: () => onChanged(null),
          icon: const Icon(Icons.undo),
          label: Text(S.of(context).toothRemoveDate),
        ),
      ],
    );
  }
}
