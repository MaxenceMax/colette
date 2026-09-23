import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/presentation/providers/custom_food_controller.dart';
import 'package:colette/features/diversification/presentation/widgets/custom_food_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  late MockCustomFoodsRepository repo;
  const kaki = Food(
    id: 'c1',
    name: 'Kaki séché',
    group: FoodGroup.vitaminAFruitsVeg,
    isCustom: true,
  );

  setUpAll(registerDiversificationFallbacks);

  setUp(() => repo = succeedingRepositories().$2);

  Future<void> open(WidgetTester tester, {Food? food}) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showCustomFoodSheet(context, food: food),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: diversificationOverrides(
        customFoods: const [kaki],
        customFoodsRepository: repo,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Food saved() =>
      verify(() => repo.save('ABCDEFGH', captureAny())).captured.single as Food;

  // La feuille dépasse souvent la hauteur de la vue de test (800×600) :
  // `find.text` par défaut ignore les éléments totalement hors du viewport
  // scrollé, donc `ensureVisible` a besoin de `skipOffstage: false` pour les
  // localiser avant de les faire défiler dans la vue.
  Future<void> ensureVisibleAndTap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text, skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('création : nom, groupe et allergènes', (tester) async {
    await open(tester);
    expect(find.text('Nouvel aliment'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Datte');
    await tester.tap(find.text('Fruits et légumes'));
    await tester.pumpAndSettle();
    await ensureVisibleAndTap(tester, 'Sulfites');
    await ensureVisibleAndTap(tester, 'Enregistrer');
    expect(
      saved(),
      const Food(
        id: 'new-id',
        name: 'Datte',
        group: FoodGroup.otherFruitsVeg,
        allergens: {Allergen.sulphites},
        isCustom: true,
      ),
    );
    expect(find.text('Nouvel aliment'), findsNothing);
  });

  testWidgets('doublon du catalogue : message, pas d\'écriture', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'carotte');
    await ensureVisibleAndTap(tester, 'Enregistrer');
    expect(find.text('Cet aliment existe déjà.'), findsOneWidget);
    verifyNever(() => repo.save(any(), any()));
  });

  testWidgets('modification : champs préremplis, id conservé', (tester) async {
    await open(tester, food: kaki);
    expect(find.text('Modifier l\'aliment'), findsOneWidget);
    expect(find.text('Kaki séché'), findsOneWidget);
    await ensureVisibleAndTap(tester, 'Enregistrer');
    expect(saved().id, 'c1');
  });

  testWidgets('contrôleur déjà en échec (aliment précédent) : feuille propre', (
    tester,
  ) async {
    // Le contrôleur `autoDispose` est partagé entre les feuilles
    // successives (`FoodDetailPage` le garde vivant, cf. commentaire dans
    // `food_detail_page.dart`) : un échec laissé par un aliment perso
    // précédent ne doit pas s'afficher tant que celle-ci n'a pas
    // elle-même tenté d'enregistrer.
    when(() => repo.delete(any(), any()))
        .thenAnswer((_) async => left(const NetworkFailure()));
    await pumpApp(
      tester,
      Consumer(
        builder: (context, ref, _) {
          // Garde le contrôleur vivant, comme le fait `FoodDetailPage`.
          ref.watch(customFoodControllerProvider);
          return Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () => ref
                      .read(customFoodControllerProvider.notifier)
                      .delete('c-precedent'),
                  child: const Text('prime'),
                ),
                TextButton(
                  onPressed: () => showCustomFoodSheet(context),
                  child: const Text('open'),
                ),
              ],
            ),
          );
        },
      ),
      overrides: diversificationOverrides(customFoodsRepository: repo),
    );
    await tester.tap(find.text('prime'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pas de connexion. Réessaie dans un instant.'),
      findsNothing,
    );
    await tester.ensureVisible(find.byType(FilledButton, skipOffstage: false));
    await tester.pumpAndSettle();
    final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(saveButton.onPressed, isNotNull);
  });
}
