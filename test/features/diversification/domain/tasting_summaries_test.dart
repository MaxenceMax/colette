import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/allergen_state.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/retry_item.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_allergen_progress.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_daily_diversity.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_foods_to_retry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const carrot = Food(
    id: 'carotte',
    name: 'Carotte',
    group: FoodGroup.vitaminAFruitsVeg,
  );
  const pasta = Food(
    id: 'pates',
    name: 'Pâtes',
    group: FoodGroup.grainsRootsTubers,
    allergens: {Allergen.gluten},
  );
  const egg = Food(
    id: 'oeuf',
    name: 'Œuf',
    group: FoodGroup.eggs,
    allergens: {Allergen.eggs},
  );
  const oil = Food(id: 'huile', name: 'Huile', group: FoodGroup.outsideGroups);
  const broccoli = Food(
    id: 'brocoli',
    name: 'Brocoli',
    group: FoodGroup.otherFruitsVeg,
  );
  final foods = {
    for (final f in [carrot, pasta, egg, oil, broccoli]) f.id: f,
  };

  Tasting tasting(
    String foodId,
    DateTime at, {
    Liking? liking,
    bool reaction = false,
  }) => Tasting(
    id: '$foodId-$at',
    foodId: foodId,
    at: at,
    liking: liking,
    hadReaction: reaction,
  );

  group('ComputeDailyDiversity', () {
    const compute = ComputeDailyDiversity();
    final now = DateTime(2027, 4, 10, 18);

    test('groupes du jour local, hors « hors groupes » et inconnus', () {
      final result = compute(
        tastings: [
          tasting('carotte', DateTime(2027, 4, 10, 12)),
          tasting('pates', DateTime(2027, 4, 10, 0)),
          tasting('huile', DateTime(2027, 4, 10, 12)),
          tasting('disparu', DateTime(2027, 4, 10, 12)),
          tasting('oeuf', DateTime(2027, 4, 9, 23, 59)),
        ],
        foodsById: foods,
        now: now,
      );
      expect(result.coveredGroups, {
        FoodGroup.vitaminAFruitsVeg,
        FoodGroup.grainsRootsTubers,
      });
      expect(result.tastingCount, 4);
    });

    test('aucune dégustation : vide', () {
      final result = compute(tastings: const [], foodsById: foods, now: now);
      expect(result.coveredGroups, isEmpty);
      expect(result.tastingCount, 0);
    });
  });

  group('ComputeAllergenProgress', () {
    const compute = ComputeAllergenProgress();

    test('9 allergènes suivis dans l\'ordre, pas encore par défaut', () {
      final result = compute(tastings: const [], foodsById: foods);
      expect(result.keys.toList(), Allergen.tracked);
      expect(result.values.toSet(), {AllergenState.notYet});
    });

    test('introduit après une dégustation sans réaction', () {
      final result = compute(
        tastings: [tasting('pates', DateTime(2027, 4, 1))],
        foodsById: foods,
      );
      expect(result[Allergen.gluten], AllergenState.introduced);
      expect(result[Allergen.eggs], AllergenState.notYet);
    });

    test(
      'une réaction l\'emporte, même suivie de dégustations sans réaction',
      () {
        final result = compute(
          tastings: [
            tasting('oeuf', DateTime(2027, 4, 5)),
            tasting('oeuf', DateTime(2027, 4, 2), reaction: true),
            tasting('oeuf', DateTime(2027, 4, 1)),
          ],
          foodsById: foods,
        );
        expect(result[Allergen.eggs], AllergenState.reaction);
      },
    );

    test('aliment inconnu ignoré', () {
      final result = compute(
        tastings: [tasting('disparu', DateTime(2027, 4, 1))],
        foodsById: foods,
      );
      expect(result.values.toSet(), {AllergenState.notYet});
    });
  });

  group('ComputeFoodsToRetry', () {
    const compute = ComputeFoodsToRetry();

    test('dernière appréciation bof ou refusé, avec le nombre d\'essais', () {
      final result = compute(
        tastings: [
          tasting('brocoli', DateTime(2027, 4, 9), liking: Liking.refused),
          tasting('carotte', DateTime(2027, 4, 8), liking: Liking.loved),
          tasting('brocoli', DateTime(2027, 4, 3), liking: Liking.meh),
          tasting('carotte', DateTime(2027, 4, 2), liking: Liking.refused),
        ],
        foodsById: foods,
      );
      expect(result, [
        const RetryItem(
          food: broccoli,
          lastLiking: Liking.refused,
          tastingCount: 2,
        ),
      ]);
    });

    test('une appréciation absente est ignorée, la précédente compte', () {
      final result = compute(
        tastings: [
          tasting('brocoli', DateTime(2027, 4, 9)),
          tasting('brocoli', DateTime(2027, 4, 3), liking: Liking.meh),
        ],
        foodsById: foods,
      );
      expect(result.single.lastLiking, Liking.meh);
      expect(result.single.tastingCount, 2);
    });

    test(
      'ordre : dégustation la plus récente d\'abord, entrée non triée acceptée',
      () {
        final result = compute(
          tastings: [
            tasting('carotte', DateTime(2027, 4, 1), liking: Liking.meh),
            tasting('brocoli', DateTime(2027, 4, 5), liking: Liking.refused),
          ],
          foodsById: foods,
        );
        expect(result.map((r) => r.food.id), ['brocoli', 'carotte']);
      },
    );

    test('aliment inconnu ignoré', () {
      final result = compute(
        tastings: [
          tasting('disparu', DateTime(2027, 4, 1), liking: Liking.refused),
        ],
        foodsById: foods,
      );
      expect(result, isEmpty);
    });
  });
}
