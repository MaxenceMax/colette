import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Demande s'il faut arrêter le minuteur en cours ; `true` pour arrêter.
Future<bool> confirmBottleTimerStop(BuildContext context) async {
  final s = S.of(context);
  final stop = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(s.bottleTimerCloseTitle),
      content: Text(s.bottleTimerCloseBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(s.bottleTimerContinue),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(s.bottleTimerStop),
        ),
      ],
    ),
  );
  return stop ?? false;
}
