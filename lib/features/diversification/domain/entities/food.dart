import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food.freezed.dart';

/// Aliment du catalogue ou ajouté par le foyer.
@freezed
abstract class Food with _$Food {
  const Food._();

  const factory Food({
    required String id,
    required String name,
    required FoodGroup group,
    @Default(<Allergen>{}) Set<Allergen> allergens,
    @Default(<FoodRule>[]) List<FoodRule> rules,
    @Default(false) bool isCustom,

    /// Référencé par une dégustation mais introuvable (catalogue et aliments perso).
    @Default(false) bool isUnknown,
  }) = _Food;

  /// Aliment introuvable : affiché « Aliment inconnu », hors diversité.
  factory Food.unknown(String id) =>
      Food(id: id, name: '', group: FoodGroup.outsideGroups, isUnknown: true);
}
