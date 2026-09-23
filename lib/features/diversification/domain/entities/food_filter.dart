import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_filter.freezed.dart';

/// Filtre principal du catalogue.
enum CatalogMode { all, notTasted, avoid }

/// Recherche et filtres du catalogue.
@freezed
abstract class FoodFilter with _$FoodFilter {
  const factory FoodFilter({
    @Default('') String query,
    @Default(CatalogMode.all) CatalogMode mode,
    Allergen? allergen,
  }) = _FoodFilter;
}
