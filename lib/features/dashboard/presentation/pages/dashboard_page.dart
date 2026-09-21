import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';

/// Onglet Aujourd'hui (placeholder, remplacé en tâche 14).
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.tabToday)),
      body: EmptyState(icon: Icons.wb_sunny_outlined, message: s.todoAllDone),
    );
  }
}
