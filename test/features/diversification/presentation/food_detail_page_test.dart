import 'dart:async';

import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/presentation/pages/food_detail_page.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  late MockTastingsRepository tastingsRepo;
  late MockCustomFoodsRepository foodsRepo;
  const kaki = Food(
    id: 'c1',
    name: 'Kaki séché',
    group: FoodGroup.vitaminAFruitsVeg,
    isCustom: true,
  );

  setUpAll(registerDiversificationFallbacks);

  setUp(() => (tastingsRepo, foodsRepo) = succeedingRepositories());

  Future<void> pump(
    WidgetTester tester,
    String foodId, {
    List<Tasting> tastings = const [],
  }) => pumpApp(
    tester,
    FoodDetailPage(foodId: foodId),
    overrides: diversificationOverrides(
      tastings: tastings,
      customFoods: const [kaki],
      tastingsRepository: tastingsRepo,
      customFoodsRepository: foodsRepo,
    ),
  );

  testWidgets('aliment à éviter : statut, règle, pas de dégustation', (
    tester,
  ) async {
    await pump(tester, 'miel');
    expect(find.text('Miel'), findsOneWidget);
    expect(find.text('À éviter avant 1 an · OMS, Anses'), findsOneWidget);
    expect(find.text('Risque de botulisme infantile.'), findsOneWidget);
    expect(find.text('Aucun allergène majeur.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Pas encore goûté.'), 200);
  });

  testWidgets('historique et suppression d\'une dégustation', (tester) async {
    await pump(
      tester,
      'carotte',
      tastings: [
        Tasting(
          id: 't1',
          foodId: 'carotte',
          at: DateTime(2027, 4, 10, 12, 5),
          liking: Liking.loved,
          note: 'Adore',
        ),
      ],
    );
    await tester.scrollUntilVisible(find.text('Aimé · Adore'), 200);
    await tester.drag(find.text('Aimé · Adore'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer cette dégustation ?'), findsOneWidget);
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    verify(() => tastingsRepo.delete('ABCDEFGH', 't1')).called(1);
  });

  testWidgets('aliment perso sans dégustation : modifiable et supprimable', (
    tester,
  ) async {
    await pump(tester, 'c1');
    expect(find.byTooltip('Modifier'), findsOneWidget);
    expect(find.text('Aliment ajouté par le foyer.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Supprimer cet aliment'), 200);
    await tester.tap(find.text('Supprimer cet aliment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    verify(() => foodsRepo.delete('ABCDEFGH', 'c1')).called(1);
  });

  testWidgets('aliment perso goûté : pas de suppression', (tester) async {
    await pump(
      tester,
      'c1',
      tastings: [Tasting(id: 't1', foodId: 'c1', at: DateTime(2027, 4, 1))],
    );
    expect(find.text('Supprimer cet aliment'), findsNothing);
  });

  testWidgets('aliment inconnu', (tester) async {
    await pump(tester, 'disparu');
    expect(find.text('Aliment inconnu'), findsOneWidget);
    expect(find.text('Noter une dégustation'), findsNothing);
  });

  testWidgets(
    'suppression : le flux perd l\'aliment avant la fin de delete, page fermée',
    (tester) async {
      // Reproduit la mise à jour optimiste du listener Firestore local : le
      // flux perd l'aliment avant même que `delete` ne rende la main.
      final controller = StreamController<List<Food>>();
      addTearDown(controller.close);
      when(() => foodsRepo.delete(any(), any())).thenAnswer((_) async {
        controller.add(const []);
        return right(null);
      });
      final overrides = [
        ...diversificationOverrides(
          customFoods: const [kaki],
          tastingsRepository: tastingsRepo,
          customFoodsRepository: foodsRepo,
        ).where((override) => override.origin != customFoodsProvider),
        customFoodsProvider.overrideWith((ref) => controller.stream),
      ];
      await pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FoodDetailPage(foodId: 'c1'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        overrides: overrides,
      );
      controller.add(const [kaki]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Supprimer cet aliment'), 200);
      await tester.tap(find.text('Supprimer cet aliment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      expect(find.text('Aliment inconnu'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    },
  );

  testWidgets(
    'suppression : une dégustation arrive pendant la confirmation, refusée',
    (tester) async {
      // Reproduit l'autre téléphone qui note une dégustation pendant que la
      // boîte de confirmation est ouverte ici : `hasTastings` devient vrai,
      // ce qui retire `_DeleteFoodButton` de l'arbre avant la fin de
      // `delete`.
      final controller = StreamController<List<Tasting>>();
      addTearDown(controller.close);
      final overrides = [
        ...diversificationOverrides(
          customFoods: const [kaki],
          tastingsRepository: tastingsRepo,
          customFoodsRepository: foodsRepo,
        ).where((override) => override.origin != tastingsProvider),
        tastingsProvider.overrideWith((ref) => controller.stream),
      ];
      await pumpApp(
        tester,
        const FoodDetailPage(foodId: 'c1'),
        overrides: overrides,
      );
      controller.add(const []);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Supprimer cet aliment'), 200);
      await tester.tap(find.text('Supprimer cet aliment'));
      await tester.pumpAndSettle();
      controller.add([
        Tasting(id: 't1', foodId: 'c1', at: DateTime(2027, 4, 1)),
      ]);
      await tester.pump();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Cet aliment a des dégustations : il ne peut pas être supprimé.',
        ),
        findsOneWidget,
      );
      verifyNever(() => foodsRepo.delete(any(), any()));
    },
  );

  testWidgets('miel après 1 an : plus de règle à éviter', (tester) async {
    await pumpApp(
      tester,
      const FoodDetailPage(foodId: 'miel'),
      overrides: diversificationOverrides(
        now: DateTime(2027, 10, 1),
        tastingsRepository: tastingsRepo,
        customFoodsRepository: foodsRepo,
      ),
    );
    expect(find.text('À éviter avant 1 an'), findsNothing);
    expect(
      find.text('Aucun repère particulier pour cet aliment.'),
      findsOneWidget,
    );
  });

  testWidgets('modification d\'une dégustation existante', (tester) async {
    await pump(
      tester,
      'carotte',
      tastings: [
        Tasting(
          id: 't1',
          foodId: 'carotte',
          at: DateTime(2027, 4, 10, 12, 5),
          liking: Liking.loved,
          note: 'Adore',
        ),
      ],
    );
    await tester.scrollUntilVisible(find.text('Aimé · Adore'), 200);
    await tester.tap(find.text('Aimé · Adore'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier la dégustation'), findsOneWidget);
    await tester.ensureVisible(find.text('Enregistrer', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => tastingsRepo.save('ABCDEFGH', captureAny()))
                .captured
                .single
            as Tasting;
    expect(saved.id, 't1');
  });
}
