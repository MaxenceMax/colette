import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('7 groupes comptent pour la diversité, dans l\'ordre OMS', () {
    expect(FoodGroup.diversityGroups, [
      FoodGroup.grainsRootsTubers,
      FoodGroup.legumesNutsSeeds,
      FoodGroup.dairy,
      FoodGroup.fleshFoods,
      FoodGroup.eggs,
      FoodGroup.vitaminAFruitsVeg,
      FoodGroup.otherFruitsVeg,
    ]);
    expect(FoodGroup.outsideGroups.countsForDiversity, isFalse);
  });

  test('14 allergènes UE, 9 suivis', () {
    expect(Allergen.values, hasLength(14));
    expect(Allergen.tracked, hasLength(9));
    expect(Allergen.tracked.first, Allergen.milk);
  });

  test('une règle est active strictement avant untilMonths', () {
    const rule = FoodRule(
      kind: RuleKind.avoid,
      untilMonths: 12,
      sources: [RuleSource.oms],
      text: 'Botulisme',
    );
    expect(rule.isActiveAt(11), isTrue);
    expect(rule.isActiveAt(12), isFalse);
    const info = FoodRule(
      kind: RuleKind.info,
      sources: [RuleSource.spf],
      text: 'x',
    );
    expect(info.isActiveAt(0), isFalse);
  });

  test('phases OMS selon les mois révolus', () {
    expect(
      DiversificationPhase.forAgeMonths(0),
      DiversificationPhase.preparation,
    );
    expect(
      DiversificationPhase.forAgeMonths(5),
      DiversificationPhase.preparation,
    );
    expect(
      DiversificationPhase.forAgeMonths(6),
      DiversificationPhase.months6To8,
    );
    expect(
      DiversificationPhase.forAgeMonths(8),
      DiversificationPhase.months6To8,
    );
    expect(
      DiversificationPhase.forAgeMonths(9),
      DiversificationPhase.months9To11,
    );
    expect(
      DiversificationPhase.forAgeMonths(12),
      DiversificationPhase.months12To23,
    );
    expect(
      DiversificationPhase.forAgeMonths(40),
      DiversificationPhase.months12To23,
    );
  });

  test('Food.unknown : hors groupes, sans règle, marqué inconnu', () {
    final food = Food.unknown('disparu');
    expect(food.id, 'disparu');
    expect(food.isUnknown, isTrue);
    expect(food.group, FoodGroup.outsideGroups);
    expect(food.rules, isEmpty);
  });
}
