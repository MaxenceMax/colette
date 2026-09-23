import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/presentation/widgets/tasting_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/catalog_fixture.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  late MockTastingsRepository repo;

  setUpAll(registerDiversificationFallbacks);

  setUp(() => repo = succeedingRepositories().$1);

  final carrot = catalogFixture().foods.firstWhere((f) => f.id == 'carotte');

  Future<void> open(WidgetTester tester, {bool withFood = false}) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                showTastingFormSheet(context, food: withFood ? carrot : null),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: diversificationOverrides(tastingsRepository: repo),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Tasting saved() =>
      verify(() => repo.save('ABCDEFGH', captureAny())).captured.single
          as Tasting;

  // Le formulaire dépasse souvent la hauteur de la vue de test (800×600) :
  // `find.text` par défaut ignore les éléments totalement hors du viewport
  // scrollé, donc `ensureVisible` a besoin de `skipOffstage: false` pour les
  // localiser avant de les faire défiler dans la vue.
  Future<void> ensureVisibleAndTap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text, skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'aliment présélectionné : enregistre à l\'heure courante et ferme',
    (tester) async {
      await open(tester, withFood: true);
      expect(find.text('Nouvelle dégustation'), findsOneWidget);
      expect(find.text('Carotte'), findsOneWidget);
      await ensureVisibleAndTap(tester, 'Bof');
      await ensureVisibleAndTap(tester, 'Réaction observée');
      expect(
        find.text(
          'En cas de gêne respiratoire, de gonflement du visage ou de malaise : appelle le 15.',
        ),
        findsOneWidget,
      );
      await ensureVisibleAndTap(tester, 'Enregistrer');
      final tasting = saved();
      expect(tasting.foodId, 'carotte');
      expect(tasting.at, testNow);
      expect(tasting.liking, Liking.meh);
      expect(tasting.hadReaction, isTrue);
      expect(find.text('Nouvelle dégustation'), findsNothing);
    },
  );

  testWidgets('sans aliment : message, pas d\'écriture', (tester) async {
    await open(tester);
    await ensureVisibleAndTap(tester, 'Enregistrer');
    expect(find.text('Choisis un aliment.'), findsOneWidget);
    verifyNever(() => repo.save(any(), any()));
  });

  testWidgets('aliment à éviter : règles affichées, confirmation demandée', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Choisir un aliment'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher un aliment'),
      'mie',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Miel'));
    await tester.pumpAndSettle();
    expect(find.text('À éviter avant 1 an'), findsOneWidget);

    await ensureVisibleAndTap(tester, 'Enregistrer');
    expect(find.text('À vérifier avant d\'enregistrer'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.save(any(), any()));

    await ensureVisibleAndTap(tester, 'Enregistrer');
    await tester.tap(find.text('Enregistrer quand même'));
    await tester.pumpAndSettle();
    expect(saved().foodId, 'miel');
  });

  testWidgets('échec d\'écriture : message dans la feuille, feuille ouverte', (
    tester,
  ) async {
    when(() => repo.save(any(), any()))
        .thenAnswer((_) async => left(const NetworkFailure()));
    await open(tester, withFood: true);
    await ensureVisibleAndTap(tester, 'Enregistrer');
    expect(
      find.text('Pas de connexion. Réessaie dans un instant.'),
      findsOneWidget,
    );
    expect(find.text('Nouvelle dégustation'), findsOneWidget);
  });
}
