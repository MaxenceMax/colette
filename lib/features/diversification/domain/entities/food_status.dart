import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_status.freezed.dart';

/// Statut d'un aliment pour l'âge courant du bébé.
@freezed
sealed class FoodStatus with _$FoodStatus {
  /// Règle `avoid` active la plus prudente.
  const factory FoodStatus.avoid({
    required int untilMonths,
    required List<RuleSource> sources,
  }) = FoodStatusAvoid;

  /// Bébé n'a pas encore 6 mois.
  const factory FoodStatus.notYetRecommended() = FoodStatusNotYetRecommended;

  /// Déjà goûté [count] fois.
  const factory FoodStatus.tasted({
    required int count,
    required bool needsPreparation,
  }) = FoodStatusTasted;

  /// Jamais goûté.
  const factory FoodStatus.notTasted({required bool needsPreparation}) =
      FoodStatusNotTasted;
}
