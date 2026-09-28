import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// En-tête du formulaire de soin : titre et bouton Fermer.
class EventFormHeader extends StatelessWidget {
  const EventFormHeader({super.key, required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            isEditing ? s.eventFormEditTitle : s.eventFormNewTitle,
            style: Theme.of(context).coletteTextStyles.heading2,
          ),
        ),
        // `maybePop` : passe par le `PopScope` du minuteur.
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: s.actionClose,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}
