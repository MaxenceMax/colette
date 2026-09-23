import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/allergen_state.dart';
import 'package:colette/features/diversification/domain/entities/daily_diversity.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group_section.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/domain/entities/retry_item.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_allergen_progress.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_daily_diversity.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_food_status.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_foods_to_retry.dart';
import 'package:colette/features/diversification/domain/use_cases/filter_foods.dart';
import 'package:colette/features/diversification/presentation/providers/catalog_filter.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diversification_overview_providers.g.dart';

List<Tasting> _tastings(Ref ref) =>
    ref.watch(tastingsProvider).value ?? const <Tasting>[];

Map<String, Food> _foods(Ref ref) =>
    ref.watch(foodsProvider).value ?? const <String, Food>{};

/// Nombre de dégustations par aliment.
@riverpod
Map<String, int> tastingCounts(Ref ref) {
  final counts = <String, int>{};
  for (final tasting in _tastings(ref)) {
    counts[tasting.foodId] = (counts[tasting.foodId] ?? 0) + 1;
  }
  return counts;
}

/// Dégustations d'un aliment, de la plus récente à la plus ancienne.
@riverpod
List<Tasting> tastingsForFood(Ref ref, String foodId) => [
  for (final tasting in _tastings(ref))
    if (tasting.foodId == foodId) tasting,
];

/// Groupes OMS couverts aujourd'hui.
@riverpod
DailyDiversity dailyDiversity(Ref ref) => const ComputeDailyDiversity()(
  tastings: _tastings(ref),
  foodsById: _foods(ref),
  now: ref.watch(currentMinuteProvider),
);

/// État des 9 allergènes suivis.
@riverpod
Map<Allergen, AllergenState> allergenProgress(Ref ref) =>
    const ComputeAllergenProgress()(
      tastings: _tastings(ref),
      foodsById: _foods(ref),
    );

/// Aliments à reproposer.
@riverpod
List<RetryItem> foodsToRetry(Ref ref) => const ComputeFoodsToRetry()(
  tastings: _tastings(ref),
  foodsById: _foods(ref),
);

/// Statut de chaque aliment pour l'âge courant (sans âge si pas de profil).
@riverpod
Map<String, FoodStatus> foodStatuses(Ref ref) {
  final ageMonths = ref.watch(diversificationTimelineProvider)?.ageMonths;
  final counts = ref.watch(tastingCountsProvider);
  return {
    for (final food in _foods(ref).values)
      food.id: const ComputeFoodStatus()(
        food: food,
        ageMonths: ageMonths,
        tastingCount: counts[food.id] ?? 0,
      ),
  };
}

/// Catalogue filtré par [CatalogFilter], groupé par groupe OMS.
@riverpod
List<FoodGroupSection> filteredCatalog(Ref ref) => const FilterFoods()(
  foods: _foods(ref).values,
  filter: ref.watch(catalogFilterProvider),
  statuses: ref.watch(foodStatusesProvider),
  tastingCounts: ref.watch(tastingCountsProvider),
);
