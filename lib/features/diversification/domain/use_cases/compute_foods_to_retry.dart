import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/retry_item.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';

/// Aliments dont la dernière dégustation appréciée vaut « bof » ou « refusé »,
/// la dégustation la plus récente d'abord. Aliments inconnus ignorés.
class ComputeFoodsToRetry {
  const ComputeFoodsToRetry();

  List<RetryItem> call({
    required List<Tasting> tastings,
    required Map<String, Food> foodsById,
  }) {
    final sorted = [...tastings]..sort((a, b) => b.at.compareTo(a.at));
    final counts = <String, int>{};
    final lastLiking = <String, Liking>{};
    for (final tasting in sorted) {
      counts[tasting.foodId] = (counts[tasting.foodId] ?? 0) + 1;
      if (tasting.liking case final liking?
          when !lastLiking.containsKey(tasting.foodId)) {
        lastLiking[tasting.foodId] = liking;
      }
    }
    return [
      for (final foodId in counts.keys)
        if ((foodsById[foodId], lastLiking[foodId])
            case (final food?, final liking?) when liking != Liking.loved)
          RetryItem(
            food: food,
            lastLiking: liking,
            tastingCount: counts[foodId]!,
          ),
    ];
  }
}
