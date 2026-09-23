import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:colette/features/diversification/domain/entities/tasting_warning.dart';
import 'package:colette/features/diversification/domain/use_cases/check_tasting_warnings.dart';
import 'package:colette/features/diversification/domain/use_cases/food_name.dart';
import 'package:colette/features/diversification/domain/use_cases/validate_custom_food.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeFoodName : minuscules, sans accents, espaces réduits', () {
    expect(normalizeFoodName('  Œuf   Dur '), 'oeuf dur');
    expect(normalizeFoodName('Épinard'), 'epinard');
    expect(normalizeFoodName('Comté'), 'comte');
  });

  test('normalizeFoodName : apostrophe typographique du clavier iOS', () {
    expect(normalizeFoodName('Huile d’olive'), "huile d'olive");
  });

  test('normalizeFoodName : marque combinante NFD retirée', () {
    // 'e' (U+0065) + accent aigu combinant (U+0301), forme NFD non composee.
    expect(normalizeFoodName('Créme'), 'creme');
  });

  group('CheckTastingWarnings', () {
    const check = CheckTastingWarnings();
    const honeyRule = FoodRule(
      kind: RuleKind.avoid,
      untilMonths: 12,
      sources: [RuleSource.oms],
      text: 'Botulisme',
    );
    const honey = Food(
      id: 'miel',
      name: 'Miel',
      group: FoodGroup.outsideGroups,
      rules: [
        honeyRule,
        FoodRule(kind: RuleKind.info, sources: [RuleSource.spf], text: 'Info'),
      ],
    );
    const carrot = Food(
      id: 'carotte',
      name: 'Carotte',
      group: FoodGroup.vitaminAFruitsVeg,
    );
    const pear = Food(
      id: 'poire',
      name: 'Poire',
      group: FoodGroup.otherFruitsVeg,
      rules: [
        FoodRule(
          kind: RuleKind.prepare,
          untilMonths: 24,
          sources: [RuleSource.spf],
          text: 'Éplucher et couper',
        ),
        FoodRule(kind: RuleKind.info, sources: [RuleSource.oms], text: 'Info'),
      ],
    );
    final birth = DateTime(2026, 9, 15);

    test('règle avoid active à la date de la dégustation', () {
      expect(check(food: honey, at: DateTime(2027, 5, 1), birthDate: birth), [
        const TastingWarning.avoidRule(honeyRule),
      ]);
      expect(
        check(food: honey, at: DateTime(2027, 9, 15), birthDate: birth),
        isEmpty,
      );
    });

    test('avant 4 mois : trop tôt', () {
      expect(check(food: carrot, at: DateTime(2027, 1, 14), birthDate: birth), [
        const TastingWarning.tooEarly(),
      ]);
      expect(
        check(food: carrot, at: DateTime(2027, 1, 15), birthDate: birth),
        isEmpty,
      );
    });

    test('sans date de naissance : aucun avertissement', () {
      expect(
        check(food: honey, at: DateTime(2027, 1, 1), birthDate: null),
        isEmpty,
      );
    });

    test('trop tôt et règle avoid actives ensemble, dans cet ordre', () {
      expect(check(food: honey, at: DateTime(2027, 1, 14), birthDate: birth), [
        const TastingWarning.tooEarly(),
        const TastingWarning.avoidRule(honeyRule),
      ]);
    });

    test('règles prepare et info seules : aucun avertissement', () {
      expect(
        check(food: pear, at: DateTime(2027, 5, 15), birthDate: birth),
        isEmpty,
      );
    });
  });

  group('ValidateCustomFood', () {
    const validate = ValidateCustomFood();

    test('nom vide', () {
      expect(
        validate(name: '   ', existingNames: const []),
        ValidationReason.emptyName,
      );
    });

    test('nom trop long', () {
      expect(
        validate(name: 'a' * 41, existingNames: const []),
        ValidationReason.foodNameTooLong,
      );
      expect(validate(name: 'a' * 40, existingNames: const []), isNull);
    });

    test('longueur mesurée en points de code, pas en unités UTF-16', () {
      expect(validate(name: '🥕' * 40, existingNames: const []), isNull);
      expect(
        validate(name: '🥕' * 41, existingNames: const []),
        ValidationReason.foodNameTooLong,
      );
    });

    test('doublon insensible aux accents et à la casse', () {
      expect(
        validate(name: 'epinard ', existingNames: const ['Épinard']),
        ValidationReason.duplicateFoodName,
      );
      expect(validate(name: 'Kaki', existingNames: const ['Épinard']), isNull);
    });

    test('doublon insensible à l\'apostrophe typographique iOS', () {
      expect(
        validate(name: 'huile d’olive', existingNames: const ["Huile d'olive"]),
        ValidationReason.duplicateFoodName,
      );
    });
  });
}
