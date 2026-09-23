import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_diversity.freezed.dart';

/// Groupes OMS couverts par les dégustations du jour.
@freezed
abstract class DailyDiversity with _$DailyDiversity {
  const factory DailyDiversity({
    required Set<FoodGroup> coveredGroups,
    required int tastingCount,
  }) = _DailyDiversity;
}
