import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';

/// Onglet Journal (placeholder, remplacé en tâche 12).
class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.journalTitle)),
      body: EmptyState(
        icon: Icons.view_timeline_outlined,
        message: s.journalEmpty,
      ),
    );
  }
}
