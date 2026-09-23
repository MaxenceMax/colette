import 'package:colette/features/diversification/presentation/widgets/phase_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    DateTime? now,
    bool withProfile = true,
  }) => pumpApp(
    tester,
    const Scaffold(body: PhaseHeader()),
    overrides: diversificationOverrides(now: now, withProfile: withProfile),
  );

  testWidgets('phase 6–8 mois et repas', (tester) async {
    await pump(tester);
    expect(find.text('Assiette'), findsOneWidget);
    expect(find.text('Phase 6–8 mois · 2 à 3 repas'), findsOneWidget);
  });

  testWidgets('préparation', (tester) async {
    await pump(tester, now: DateTime(2026, 10, 1));
    expect(find.text('Préparation · Lait uniquement'), findsOneWidget);
  });

  testWidgets('sans profil : invitation à le renseigner', (tester) async {
    await pump(tester, withProfile: false);
    expect(
      find.text(
        'Renseigne le profil du bébé dans Réglages pour voir les repères selon son âge.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'ⓘ ouvre les repères de la phase, les sources et l\'avertissement',
    (tester) async {
      await pump(tester);
      await tester.tap(find.byTooltip('Repères à son âge'));
      await tester.pumpAndSettle();
      expect(find.text('Repas et textures · Phase 6–8 mois'), findsOneWidget);
      expect(find.text('Purées lisses puis écrasées.'), findsOneWidget);
      // Les `SelectableText` des sources contiennent chacun un `Scrollable`
      // interne : on cible explicitement celui de la `ListView` (le premier
      // dans l'arbre) pour que `scrollUntilVisible` reste sans ambiguïté.
      final listScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('OMS 2023'),
        200,
        scrollable: listScrollable,
      );
      expect(find.text('OMS 2023'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(
          'Informations générales : elles ne remplacent pas l\'avis de ton pédiatre.',
        ),
        200,
        scrollable: listScrollable,
      );
    },
  );
}
