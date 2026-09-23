import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page Sommeil : frise des 7 derniers jours et détail du jour choisi.
class SleepPage extends ConsumerStatefulWidget {
  const SleepPage({super.key});

  @override
  ConsumerState<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends ConsumerState<SleepPage> {
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(S.of(context).sleepPageTitle)));
}
