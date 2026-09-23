import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_filter.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:colette/features/diversification/domain/use_cases/filter_foods.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const filter = FilterFoods();
  const carrot = Food(
    id: 'carotte',
    name: 'Carotte',
    group: FoodGroup.vitaminAFruitsVeg,
  );
  const squash = Food(
    id: 'courge',
    name: 'Courge',
    group: FoodGroup.vitaminAFruitsVeg,
  );
  const egg = Food(
    id: 'oeuf',
    name: 'Œuf dur',
    group: FoodGroup.eggs,
    allergens: {Allergen.eggs},
  );
  const honey = Food(id: 'miel', name: 'Miel', group: FoodGroup.outsideGroups);
  final unknown = Food.unknown('disparu');
  final foods = [honey, squash, egg, carrot, unknown];
  final statuses = <String, FoodStatus>{
    'carotte': const FoodStatus.tasted(count: 2, needsPreparation: false),
    'courge': const FoodStatus.notTasted(needsPreparation: false),
    'oeuf': const FoodStatus.notTasted(needsPreparation: false),
    'miel': const FoodStatus.avoid(untilMonths: 12, sources: [RuleSource.oms]),
  };
  const counts = {'carotte': 2, 'miel': 1};

  // Les identifiants sont joints en une String (et non gardés en List<String>) :
  // les records Dart comparent leurs champs avec `==`, et `List` ne redéfinit
  // pas `==` (identité), donc deux listes distinctes mais égales ne
  // correspondraient jamais via `expect`.
  List<(FoodGroup, String)> run(FoodFilter f) => [
    for (final section in filter(
      foods: foods,
      filter: f,
      statuses: statuses,
      tastingCounts: counts,
    ))
      (section.group, section.foods.map((food) => food.id).join(', ')),
  ];

  test('tous : groupés dans l\'ordre OMS, triés par nom, inconnus exclus', () {
    expect(run(const FoodFilter()), [
      (FoodGroup.eggs, 'oeuf'),
      (FoodGroup.vitaminAFruitsVeg, 'carotte, courge'),
      (FoodGroup.outsideGroups, 'miel'),
    ]);
  });

  test('recherche insensible aux accents', () {
    expect(run(const FoodFilter(query: 'OEUF')), [(FoodGroup.eggs, 'oeuf')]);
  });

  test('pas goûtés : sans aucune dégustation, quel que soit le statut', () {
    expect(run(const FoodFilter(mode: CatalogMode.notTasted)), [
      (FoodGroup.eggs, 'oeuf'),
      (FoodGroup.vitaminAFruitsVeg, 'courge'),
    ]);
  });

  test('à éviter : statut avoid', () {
    expect(run(const FoodFilter(mode: CatalogMode.avoid)), [
      (FoodGroup.outsideGroups, 'miel'),
    ]);
  });

  test('filtre allergène', () {
    expect(run(const FoodFilter(allergen: Allergen.eggs)), [
      (FoodGroup.eggs, 'oeuf'),
    ]);
  });

  test('aucun résultat : liste vide', () {
    expect(run(const FoodFilter(query: 'zzz')), isEmpty);
  });
}
