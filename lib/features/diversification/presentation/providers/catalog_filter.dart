import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food_filter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'catalog_filter.g.dart';

/// Recherche et filtres du catalogue, partagés entre la carte Allergènes et la liste.
@riverpod
class CatalogFilter extends _$CatalogFilter {
  @override
  FoodFilter build() => const FoodFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setMode(CatalogMode mode) => state = state.copyWith(mode: mode);

  void setAllergen(Allergen? allergen) =>
      state = state.copyWith(allergen: allergen);
}
