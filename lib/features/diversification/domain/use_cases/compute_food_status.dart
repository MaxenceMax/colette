import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';

/// Statut d'un aliment : règle `avoid` la plus prudente, puis « dès 6 mois »,
/// puis goûté / pas encore. Sans âge ([ageMonths] `null`), seules les
/// dégustations comptent et toute règle `prepare` est considérée active.
class ComputeFoodStatus {
  const ComputeFoodStatus();

  FoodStatus call({
    required Food food,
    required int? ageMonths,
    required int tastingCount,
  }) {
    if (ageMonths != null) {
      final avoid = _strictestActiveAvoid(food.rules, ageMonths);
      if (avoid != null) {
        return FoodStatus.avoid(
          untilMonths: avoid.untilMonths!,
          sources: avoid.sources,
        );
      }
      if (ageMonths < DiversificationAges.whoStartMonths) {
        return const FoodStatus.notYetRecommended();
      }
    }
    final needsPreparation = food.rules.any(
      (rule) =>
          rule.kind == RuleKind.prepare &&
          (ageMonths == null || rule.isActiveAt(ageMonths)),
    );
    return tastingCount > 0
        ? FoodStatus.tasted(
            count: tastingCount,
            needsPreparation: needsPreparation,
          )
        : FoodStatus.notTasted(needsPreparation: needsPreparation);
  }

  static FoodRule? _strictestActiveAvoid(List<FoodRule> rules, int ageMonths) {
    FoodRule? strictest;
    for (final rule in rules) {
      if (rule.kind != RuleKind.avoid || !rule.isActiveAt(ageMonths)) continue;
      if (strictest == null || rule.untilMonths! > strictest.untilMonths!) {
        strictest = rule;
      }
    }
    return strictest;
  }
}
