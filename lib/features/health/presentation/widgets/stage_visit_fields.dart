import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Visite faite : bouton, date et note.
class StageVisitFields extends StatelessWidget {
  const StageVisitFields({
    super.key,
    required this.doneAt,
    required this.note,
    required this.defaultDate,
    required this.minimum,
    required this.maximum,
    required this.onDoneChanged,
  });

  final DateTime? doneAt;
  final TextEditingController note;
  final DateTime defaultDate;
  final DateTime minimum;
  final DateTime maximum;
  final ValueChanged<DateTime?> onDoneChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: doneAt ?? defaultDate,
      mode: CupertinoDatePickerMode.date,
      minimum: minimum,
      maximum: maximum,
    );
    if (picked != null) onDoneChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final done = doneAt;
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.sm.value,
      children: [
        if (done == null)
          OutlinedButton.icon(
            onPressed: () => onDoneChanged(defaultDate),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(s.healthSheetMarkDone),
          )
        else ...[
          DateField(
            label: s.healthSheetDoneOn,
            value: formatShortDate(done),
            onTap: () => _pick(context),
          ),
          TextButton.icon(
            onPressed: () => onDoneChanged(null),
            icon: const Icon(Icons.undo),
            label: Text(s.healthSheetCancelDone),
          ),
        ],
        TextField(
          controller: note,
          decoration: InputDecoration(labelText: s.healthSheetNote),
          maxLines: null,
        ),
      ],
    );
  }
}
