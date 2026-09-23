import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/diversification/domain/entities/tasting_warning.dart';
import 'package:colette/features/diversification/presentation/widgets/rule_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Liste les avertissements ; `true` si l'utilisateur confirme l'enregistrement.
Future<bool> showTastingWarningsDialog(
  BuildContext context,
  List<TastingWarning> warnings,
) async {
  final s = S.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(s.tastingWarningsTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            for (final warning in warnings)
              switch (warning) {
                TastingWarningTooEarly() => Padding(
                  padding: AppSpacing.xs.vertical,
                  child: Text(s.tastingWarningTooEarly),
                ),
                TastingWarningAvoidRule(:final rule) => RuleTile(rule: rule),
              },
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(s.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(s.tastingWarningsConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
