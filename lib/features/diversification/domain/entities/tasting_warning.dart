import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tasting_warning.freezed.dart';

/// Avertissement à confirmer avant d'enregistrer une dégustation.
@freezed
sealed class TastingWarning with _$TastingWarning {
  /// Règle `avoid` active à l'âge du bébé au moment de la dégustation.
  const factory TastingWarning.avoidRule(FoodRule rule) =
      TastingWarningAvoidRule;

  /// Bébé a moins de 4 mois.
  const factory TastingWarning.tooEarly() = TastingWarningTooEarly;
}
