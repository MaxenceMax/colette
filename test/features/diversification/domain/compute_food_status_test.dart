import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_food_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeFoodStatus();
  const carrot = Food(
    id: 'carotte',
    name: 'Carotte',
    group: FoodGroup.vitaminAFruitsVeg,
  );
  const honey = Food(
    id: 'miel',
    name: 'Miel',
    group: FoodGroup.outsideGroups,
    rules: [
      FoodRule(
        kind: RuleKind.avoid,
        untilMonths: 12,
        sources: [RuleSource.oms, RuleSource.anses],
        text: 'Botulisme',
      ),
    ],
  );
  const cowMilk = Food(
    id: 'lait-de-vache',
    name: 'Lait de vache',
    group: FoodGroup.dairy,
    rules: [
      FoodRule(
        kind: RuleKind.info,
        sources: [RuleSource.oms],
        text: 'Acceptable dès 6 mois',
      ),
      FoodRule(
        kind: RuleKind.avoid,
        untilMonths: 12,
        sources: [RuleSource.anses, RuleSource.spf],
        text: 'Pas en boisson',
      ),
    ],
  );
  const wholeNuts = Food(
    id: 'fruits-a-coque-entiers',
    name: 'Fruits à coque entiers',
    group: FoodGroup.legumesNutsSeeds,
    rules: [
      FoodRule(
        kind: RuleKind.avoid,
        untilMonths: 36,
        sources: [RuleSource.anses],
        text: '3 ans',
      ),
      FoodRule(
        kind: RuleKind.avoid,
        untilMonths: 60,
        sources: [RuleSource.spf],
        text: '5 ans',
      ),
    ],
  );
  const grape = Food(
    id: 'raisin',
    name: 'Raisin',
    group: FoodGroup.otherFruitsVeg,
    rules: [
      FoodRule(
        kind: RuleKind.prepare,
        untilMonths: 60,
        sources: [RuleSource.spf],
        text: 'Couper',
      ),
    ],
  );

  test('règle avoid active : à éviter, avec ses sources', () {
    expect(
      compute(food: honey, ageMonths: 8, tastingCount: 0),
      const FoodStatus.avoid(
        untilMonths: 12,
        sources: [RuleSource.oms, RuleSource.anses],
      ),
    );
  });

  test('avoid prime sur « pas encore 6 mois » et sur les dégustations', () {
    expect(
      compute(food: honey, ageMonths: 3, tastingCount: 2),
      isA<FoodStatusAvoid>(),
    );
  });

  test('règle échue : statut normal', () {
    expect(
      compute(food: honey, ageMonths: 12, tastingCount: 0),
      const FoodStatus.notTasted(needsPreparation: false),
    );
  });

  test('sources divergentes : la règle active la plus prudente l\'emporte', () {
    expect(
      compute(food: cowMilk, ageMonths: 7, tastingCount: 0),
      const FoodStatus.avoid(
        untilMonths: 12,
        sources: [RuleSource.anses, RuleSource.spf],
      ),
    );
    expect(
      compute(food: wholeNuts, ageMonths: 40, tastingCount: 0),
      const FoodStatus.avoid(untilMonths: 60, sources: [RuleSource.spf]),
    );
    expect(
      compute(food: wholeNuts, ageMonths: 20, tastingCount: 0),
      const FoodStatus.avoid(untilMonths: 60, sources: [RuleSource.spf]),
    );
  });

  test('avant 6 mois : pas encore recommandé', () {
    expect(
      compute(food: carrot, ageMonths: 5, tastingCount: 1),
      const FoodStatus.notYetRecommended(),
    );
  });

  test('goûté ou pas encore, avec précaution de préparation active', () {
    expect(
      compute(food: grape, ageMonths: 8, tastingCount: 0),
      const FoodStatus.notTasted(needsPreparation: true),
    );
    expect(
      compute(food: grape, ageMonths: 8, tastingCount: 3),
      const FoodStatus.tasted(count: 3, needsPreparation: true),
    );
    expect(
      compute(food: grape, ageMonths: 60, tastingCount: 3),
      const FoodStatus.tasted(count: 3, needsPreparation: false),
    );
  });

  test('sans profil : ni avoid ni « pas encore », prepare considéré actif', () {
    expect(
      compute(food: honey, ageMonths: null, tastingCount: 0),
      const FoodStatus.notTasted(needsPreparation: false),
    );
    expect(
      compute(food: grape, ageMonths: null, tastingCount: 1),
      const FoodStatus.tasted(count: 1, needsPreparation: true),
    );
  });
}
