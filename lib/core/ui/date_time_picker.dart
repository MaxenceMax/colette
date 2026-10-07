import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Ouvre un sélecteur Cupertino et renvoie la date choisie, ou `null`.
Future<DateTime?> showColetteDateTimePicker(
  BuildContext context, {
  required DateTime initial,
  required CupertinoDatePickerMode mode,
  DateTime? maximum,
  DateTime? minimum,

  /// Pas des minutes ; l'heure initiale est arrondie à ce pas, exigé par
  /// `CupertinoDatePicker`.
  int minuteInterval = 1,
}) {
  var safeInitial = initial;
  if (maximum != null && safeInitial.isAfter(maximum)) safeInitial = maximum;
  if (minimum != null && safeInitial.isBefore(minimum)) safeInitial = minimum;
  safeInitial = safeInitial.subtract(
    Duration(minutes: safeInitial.minute % minuteInterval),
  );
  var selected = safeInitial;
  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: .min,
        children: [
          // La roue cède la place au bouton quand la feuille est trop basse.
          Flexible(
            child: SizedBox(
              height: AppSize.massive.value * 2,
              child: CupertinoDatePicker(
                mode: mode,
                initialDateTime: safeInitial,
                maximumDate: maximum,
                minimumDate: minimum,
                minuteInterval: minuteInterval,
                use24hFormat: true,
                onDateTimeChanged: (value) => selected = value,
              ),
            ),
          ),
          Padding(
            padding: AppSpacing.md.all,
            child: FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(selected),
              child: Text(S.of(sheetContext).actionChoose),
            ),
          ),
        ],
      ),
    ),
  );
}
