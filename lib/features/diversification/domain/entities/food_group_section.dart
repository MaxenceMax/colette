import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_group_section.freezed.dart';

/// Aliments d'un groupe, après filtrage du catalogue.
@freezed
abstract class FoodGroupSection with _$FoodGroupSection {
  const factory FoodGroupSection({
    required FoodGroup group,
    required List<Food> foods,
  }) = _FoodGroupSection;
}
