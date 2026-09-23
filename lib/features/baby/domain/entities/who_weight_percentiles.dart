import 'package:freezed_annotation/freezed_annotation.dart';

part 'who_weight_percentiles.freezed.dart';

/// Poids de référence OMS d'un jour de vie : 3e, 50e et 97e percentiles.
@freezed
abstract class WhoWeightPercentiles with _$WhoWeightPercentiles {
  const factory WhoWeightPercentiles({
    required int ageDays,
    required DateTime date,
    required int p3Grams,
    required int p50Grams,
    required int p97Grams,
  }) = _WhoWeightPercentiles;
}
