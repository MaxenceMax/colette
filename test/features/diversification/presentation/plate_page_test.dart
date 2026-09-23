import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/presentation/pages/plate_page.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  final tastings = [
    Tasting(
      id: '1',
      foodId: 'carotte',
      at: DateTime(2027, 4, 10, 12),
      liking: Liking.loved,
    ),
    Tasting(id: '2', foodId: 'carotte', at: DateTime(2027, 4, 9)),
    Tasting(
      id: '3',
      foodId: 'brocoli',
      at: DateTime(2027, 4, 8),
      liking: Liking.refused,
    ),
  ];

  Future<void> pump(WidgetTester tester, {DateTime? now}) => pumpApp(
    tester,
    const PlatePage(),
    overrides: diversificationOverrides(now: now, tastings: tastings),
  );

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );

  testWidgets('phase active : diversité du jour, allergènes, catalogue', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Phase 6–8 mois · 2 à 3 repas'), findsOneWidget);
    expect(find.text('1 groupe sur 7'), findsOneWidget);
    expect(find.text('Allergènes'), findsOneWidget);
    await scrollTo(tester, find.text('Aliments · 2 goûtés'));
    await scrollTo(tester, find.text('Goûté ×2'));
    expect(find.text('Goûté ×2'), findsOneWidget);
  });

  testWidgets('avant 6 mois : carte préparation, statuts « dès 6 mois »', (
    tester,
  ) async {
    await pump(tester, now: DateTime(2026, 12, 1));
    expect(find.text('Bientôt la diversification'), findsOneWidget);
    // `scrollUntilVisible` exige un finder résolvant à un seul élément (pour
    // son `Scrollable.ensureVisible` final) : on défile jusqu'à un nom
    // d'aliment unique plutôt que jusqu'au badge de statut, partagé par
    // plusieurs aliments avant 6 mois.
    await scrollTo(tester, find.text('Carotte'));
    expect(find.text('Dès 6 mois (OMS)'), findsWidgets);
  });

  testWidgets('recherche', (tester) async {
    await pump(tester);
    await scrollTo(
      tester,
      find.widgetWithText(TextField, 'Rechercher un aliment'),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher un aliment'),
      'mie',
    );
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Miel'));
    expect(find.text('Carotte'), findsNothing);
  });

  testWidgets('filtre « À éviter »', (tester) async {
    await pump(tester);
    await scrollTo(tester, find.text('À éviter'));
    await tester.ensureVisible(find.text('À éviter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('À éviter'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Miel'));
    expect(find.text('Carotte'), findsNothing);
  });

  testWidgets('tap sur un allergène : filtre le catalogue', (tester) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Œuf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Œuf'));
    await tester.pumpAndSettle();
    expect(find.text('Contient : Œuf'), findsOneWidget);
    await scrollTo(tester, find.text('Œuf bien cuit'));
    expect(find.text('Carotte'), findsNothing);
  });

  testWidgets('catalogue en erreur : message', (tester) async {
    await pumpApp(
      tester,
      const PlatePage(),
      overrides: diversificationOverrides(catalogError: StateError('KO')),
    );
    expect(find.text('Une erreur est survenue.'), findsOneWidget);
  });

  testWidgets('aliments perso en erreur réseau : message', (tester) async {
    final overrides = [
      ...diversificationOverrides(tastings: tastings)
          .where((override) => override.origin != customFoodsProvider),
      customFoodsProvider.overrideWith(
        (ref) => Stream.error(const NetworkFailure()),
      ),
    ];
    await pumpApp(tester, const PlatePage(), overrides: overrides);
    expect(
      find.text('Pas de connexion. Réessaie dans un instant.'),
      findsOneWidget,
    );
  });

  testWidgets('dégustations en erreur réseau : message', (tester) async {
    final overrides = [
      ...diversificationOverrides().where(
        (override) => override.origin != tastingsProvider,
      ),
      tastingsProvider.overrideWith(
        (ref) => Stream.error(const NetworkFailure()),
      ),
    ];
    await pumpApp(tester, const PlatePage(), overrides: overrides);
    expect(
      find.text('Pas de connexion. Réessaie dans un instant.'),
      findsOneWidget,
    );
  });
}
