import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_rule.freezed.dart';

/// Nature d'une règle : à éviter, précaution de préparation, simple conseil.
enum RuleKind { avoid, prepare, info }

/// Règle d'un aliment, avec son âge limite éventuel et ses sources.
@freezed
abstract class FoodRule with _$FoodRule {
  const FoodRule._();

  const factory FoodRule({
    required RuleKind kind,

    /// Âge (mois révolus) à partir duquel la règle ne s'applique plus ;
    /// obligatoire pour `avoid` et `prepare`, absent pour `info`.
    int? untilMonths,
    required List<RuleSource> sources,
    required String text,
  }) = _FoodRule;

  /// `true` si la règle a un âge limite et que [ageMonths] est en dessous.
  bool isActiveAt(int ageMonths) {
    final until = untilMonths;
    return until != null && ageMonths < until;
  }
}
