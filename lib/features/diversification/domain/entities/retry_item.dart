import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'retry_item.freezed.dart';

/// Aliment à reproposer : dernière appréciation « bof » ou « refusé ».
@freezed
abstract class RetryItem with _$RetryItem {
  const factory RetryItem({
    required Food food,
    required Liking lastLiking,
    required int tastingCount,
  }) = _RetryItem;
}
