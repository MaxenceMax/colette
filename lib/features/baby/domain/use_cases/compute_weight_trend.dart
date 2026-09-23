import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/domain/entities/weight_trend.dart';

/// Dernière pesée comparée à la plus récente d'un jour civil antérieur.
class ComputeWeightTrend {
  const ComputeWeightTrend();

  WeightTrend? call(List<WeightEntry> weights) {
    if (weights.isEmpty) return null;
    final sorted = [...weights]
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    final latest = sorted.first;
    final latestDay = latest.measuredAt.dateOnly;
    final previous = sorted
        .where((w) => w.measuredAt.isBefore(latestDay))
        .firstOrNull;
    return WeightTrend(latest: latest, previous: previous);
  }
}
