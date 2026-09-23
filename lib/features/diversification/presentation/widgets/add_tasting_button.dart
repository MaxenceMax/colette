import 'package:colette/features/diversification/presentation/widgets/tasting_form_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Bouton « Noter une dégustation », sans aliment présélectionné.
class AddTastingButton extends StatelessWidget {
  const AddTastingButton({super.key});

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: () => showTastingFormSheet(context),
    icon: const Icon(Icons.add),
    label: Text(S.of(context).actionAddTasting),
  );
}
