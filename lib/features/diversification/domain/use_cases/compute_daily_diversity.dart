import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/diversification/domain/entities/daily_diversity.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';

/// Groupes OMS couverts le jour civil de [now] ; les aliments inconnus et
/// « hors groupes » comptent comme dégustations mais pas comme groupes.
class ComputeDailyDiversity {
  const ComputeDailyDiversity();

  DailyDiversity call({
    required List<Tasting> tastings,
    required Map<String, Food> foodsById,
    required DateTime now,
  }) {
    final today = [
      for (final tasting in tastings)
        if (tasting.at.isSameDay(now)) tasting,
    ];
    return DailyDiversity(
      coveredGroups: {
        for (final tasting in today)
          if (foodsById[tasting.foodId]?.group case final group?
              when group.countsForDiversity)
            group,
      },
      tastingCount: today.length,
    );
  }
}
