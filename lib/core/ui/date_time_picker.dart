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
}) {
  var safeInitial = initial;
  if (maximum != null && safeInitial.isAfter(maximum)) safeInitial = maximum;
  if (minimum != null && safeInitial.isBefore(minimum)) safeInitial = minimum;
  var selected = safeInitial;
  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: .min,
        children: [
          SizedBox(
            height: AppSize.massive.value * 2,
            child: CupertinoDatePicker(
              mode: mode,
              initialDateTime: safeInitial,
              maximumDate: maximum,
              minimumDate: minimum,
              use24hFormat: true,
              onDateTimeChanged: (value) => selected = value,
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
