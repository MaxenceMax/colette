import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';

/// Onglet Réglages (placeholder, remplacé en tâche 15).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: EmptyState(icon: Icons.tune_outlined, message: s.settingsTitle),
    );
  }
}
