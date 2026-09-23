import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_filter.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_group_section.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/domain/use_cases/food_name.dart';

/// Applique recherche et filtres, puis groupe par [FoodGroup] (ordre de l'enum)
/// avec les aliments triés par nom normalisé. Les aliments inconnus sont exclus.
class FilterFoods {
  const FilterFoods();

  List<FoodGroupSection> call({
    required Iterable<Food> foods,
    required FoodFilter filter,
    required Map<String, FoodStatus> statuses,
    required Map<String, int> tastingCounts,

    /// Âge du bébé, `null` sans profil : [CatalogMode.avoid] se base alors
    /// directement sur les règles `avoid` de l'aliment, faute de [FoodStatus]
    /// calculé pour un âge.
    required int? ageMonths,
  }) {
    final query = normalizeFoodName(filter.query);
    bool keep(Food food) {
      if (food.isUnknown) return false;
      if (query.isNotEmpty && !normalizeFoodName(food.name).contains(query)) {
        return false;
      }
      if (filter.allergen case final allergen?
          when !food.allergens.contains(allergen)) {
        return false;
      }
      return switch (filter.mode) {
        CatalogMode.all => true,
        CatalogMode.notTasted => (tastingCounts[food.id] ?? 0) == 0,
        CatalogMode.avoid =>
          ageMonths == null
              ? food.rules.any((rule) => rule.kind == RuleKind.avoid)
              : statuses[food.id] is FoodStatusAvoid,
      };
    }

    final kept = foods.where(keep).toList();
    final normalizedNames = {
      for (final food in kept) food.id: normalizeFoodName(food.name),
    };
    kept.sort(
      (a, b) => normalizedNames[a.id]!.compareTo(normalizedNames[b.id]!),
    );
    return [
      for (final group in FoodGroup.values)
        if (kept.where((food) => food.group == group).toList()
            case final groupFoods when groupFoods.isNotEmpty)
          FoodGroupSection(group: group, foods: groupFoods),
    ];
  }
}
