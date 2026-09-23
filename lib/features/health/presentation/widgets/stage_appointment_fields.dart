import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Date et heure du RDV, praticien, et bouton pour retirer le RDV.
class StageAppointmentFields extends StatelessWidget {
  const StageAppointmentFields({
    super.key,
    required this.appointmentAt,
    required this.practitioner,
    required this.minimum,
    required this.initialPick,
    required this.onChanged,
  });

  final DateTime? appointmentAt;
  final TextEditingController practitioner;

  /// Borne basse du sélecteur (naissance).
  final DateTime minimum;

  /// Date proposée quand aucun RDV n'est posé.
  final DateTime initialPick;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: appointmentAt ?? initialPick,
      mode: CupertinoDatePickerMode.dateAndTime,
      minimum: minimum,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.sm.value,
      children: [
        DateField(
          label: s.healthSheetAppointment,
          value: appointmentAt == null
              ? s.healthSheetPickAppointment
              : formatDayAndTime(appointmentAt!),
          onTap: () => _pick(context),
        ),
        if (appointmentAt != null) ...[
          TextField(
            controller: practitioner,
            decoration: InputDecoration(labelText: s.healthSheetPractitioner),
            textCapitalization: .words,
          ),
          Align(
            alignment: .centerLeft,
            child: TextButton.icon(
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.event_busy_outlined),
              label: Text(s.healthSheetRemoveAppointment),
            ),
          ),
        ],
      ],
    );
  }
}
