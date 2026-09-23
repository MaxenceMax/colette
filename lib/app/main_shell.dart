import 'package:colette/app/widgets/colette_tab_bar.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scaffold commun aux cinq onglets : bandeau hors ligne + barre maison avec
/// Aujourd'hui au centre.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Index de la branche Aujourd'hui, portée par le bouton central.
  static const todayIndex = 2;

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
      bottomNavigationBar: ColetteTabBar(
        selectedIndex: navigationShell.currentIndex,
        centerIndex: todayIndex,
        centerIcon: Icons.wb_sunny,
        centerLabel: s.tabToday,
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          ColetteTabDestination(
            icon: Icons.view_timeline_outlined,
            selectedIcon: Icons.view_timeline,
            label: s.tabJournal,
          ),
          ColetteTabDestination(
            icon: Icons.rice_bowl_outlined,
            selectedIcon: Icons.rice_bowl,
            label: s.tabPlate,
          ),
          ColetteTabDestination(
            icon: Icons.medical_services_outlined,
            selectedIcon: Icons.medical_services,
            label: s.tabHealth,
          ),
          ColetteTabDestination(
            icon: Icons.tune_outlined,
            selectedIcon: Icons.tune,
            label: s.tabSettings,
          ),
        ],
      ),
    );
  }
}
