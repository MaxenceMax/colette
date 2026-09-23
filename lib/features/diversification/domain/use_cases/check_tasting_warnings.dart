import 'dart:math';

import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/tasting_warning.dart';

/// Avertissements à confirmer avant d'enregistrer : bébé de moins de 4 mois
/// à la date [at], règles `avoid` actives à cet âge. Vide sans date de naissance.
class CheckTastingWarnings {
  const CheckTastingWarnings();

  List<TastingWarning> call({
    required Food food,
    required DateTime at,
    required DateTime? birthDate,
  }) {
    if (birthDate == null) return const [];
    final ageMonths = max(0, completedMonthsBetween(birthDate, at));
    return [
      if (ageMonths < DiversificationAges.franceMinMonths)
        const TastingWarning.tooEarly(),
      for (final rule in food.rules)
        if (rule.kind == RuleKind.avoid && rule.isActiveAt(ageMonths))
          TastingWarning.avoidRule(rule),
    ];
  }
}
