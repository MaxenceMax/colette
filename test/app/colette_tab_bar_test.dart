import 'package:colette/app/widgets/colette_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  const destinations = [
    ColetteTabDestination(
      icon: Icons.view_timeline_outlined,
      selectedIcon: Icons.view_timeline,
      label: 'Journal',
    ),
    ColetteTabDestination(
      icon: Icons.rice_bowl_outlined,
      selectedIcon: Icons.rice_bowl,
      label: 'Assiette',
    ),
    ColetteTabDestination(
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services,
      label: 'Santé',
    ),
    ColetteTabDestination(
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
      label: 'Réglages',
    ),
  ];

  Future<List<int>> pumpBar(WidgetTester tester, {int selected = 2}) async {
    final taps = <int>[];
    await pumpApp(
      tester,
      Scaffold(
        bottomNavigationBar: ColetteTabBar(
          destinations: destinations,
          centerIcon: Icons.wb_sunny,
          centerLabel: 'Aujourd\'hui',
          centerIndex: 2,
          selectedIndex: selected,
          onSelected: taps.add,
        ),
      ),
    );
    return taps;
  }

  testWidgets('les destinations renvoient leur index de branche', (
    tester,
  ) async {
    final taps = await pumpBar(tester);
    for (final label in ['Journal', 'Assiette', 'Santé', 'Réglages']) {
      await tester.tap(find.text(label));
    }
    await tester.tap(find.byTooltip('Aujourd\'hui'));
    expect(taps, [0, 1, 3, 4, 2]);
  });

  testWidgets('la sélection colore l\'icône pleine, le centre est accessible', (
    tester,
  ) async {
    await pumpBar(tester, selected: 3);
    expect(find.byIcon(Icons.medical_services), findsOneWidget);
    expect(find.byIcon(Icons.view_timeline_outlined), findsOneWidget);
    expect(find.text('Aujourd\'hui'), findsNothing);
    final semantics = tester.getSemantics(find.byTooltip('Aujourd\'hui'));
    expect(semantics.label, contains('Aujourd\'hui'));
  });
}
