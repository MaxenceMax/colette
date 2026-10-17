import 'package:colette/features/diversification/presentation/widgets/pediatrician_advice_sheet.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  Future<void> pump(WidgetTester tester, {bool withProfile = true}) => pumpApp(
    tester,
    const Scaffold(body: PediatricianAdviceSheet()),
    overrides: diversificationOverrides(withProfile: withProfile),
  );

  testWidgets('toutes les consignes, étape du moment signalée', (tester) async {
    await pump(tester);
    expect(find.text('Diversification et allergies'), findsOneWidget);
    expect(find.text('Dr Test'), findsOneWidget);
    expect(find.text('Sauf lait HPLV.'), findsOneWidget);
    expect(find.text('À partir de 3 mois'), findsOneWidget);
    expect(find.text('Yaourts natures.'), findsOneWidget);
    expect(find.text('Protéines :'), findsOneWidget);
    expect(find.text('Œuf dur 1 fois par semaine.'), findsOneWidget);
    expect(find.text('À éviter'), findsOneWidget);
    expect(find.text('Pas de petit-suisse.'), findsOneWidget);
    final badge = find.text('En ce moment');
    expect(badge, findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: badge, matching: find.byType(SectionHeader)),
        matching: find.text('À partir de 4 mois'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sans profil : aucune étape signalée', (tester) async {
    await pump(tester, withProfile: false);
    expect(find.text('À partir de 4 mois'), findsOneWidget);
    expect(find.text('En ce moment'), findsNothing);
  });
}
