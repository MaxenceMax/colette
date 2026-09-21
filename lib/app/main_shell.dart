import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scaffold commun aux trois onglets : bandeau hors ligne + `NavigationBar`.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny_outlined),
            selectedIcon: const Icon(Icons.wb_sunny),
            label: s.tabToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_timeline_outlined),
            selectedIcon: const Icon(Icons.view_timeline),
            label: s.tabJournal,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune),
            label: s.tabSettings,
          ),
        ],
      ),
    );
  }
}
