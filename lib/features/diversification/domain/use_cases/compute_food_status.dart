import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';

/// Statut d'un aliment : règle(s) `avoid` la plus prudente (union des sources,
/// dans l'ordre de première apparition, en cas d'égalité), puis « dès 6 mois »,
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
    final active = [
      for (final rule in rules)
        if (rule.kind == RuleKind.avoid && rule.isActiveAt(ageMonths)) rule,
    ];
    if (active.isEmpty) return null;
    final strictestUntil = active
        .map((rule) => rule.untilMonths!)
        .reduce((a, b) => a > b ? a : b);
    final strictestRules = active.where(
      (rule) => rule.untilMonths == strictestUntil,
    );
    final sources = <RuleSource>[];
    for (final rule in strictestRules) {
      for (final source in rule.sources) {
        if (!sources.contains(source)) sources.add(source);
      }
    }
    return FoodRule(
      kind: RuleKind.avoid,
      untilMonths: strictestUntil,
      sources: sources,
      text: strictestRules.first.text,
    );
  }
}
