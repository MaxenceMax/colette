import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Boîte de confirmation partagée par les suppressions du Journal (soin, sommeil).
Future<bool?> confirmTimelineDelete(
  BuildContext context, {
  required String title,
}) {
  final s = S.of(context);
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(s.deleteEventBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(s.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(s.actionDelete),
        ),
      ],
    ),
  );
}
