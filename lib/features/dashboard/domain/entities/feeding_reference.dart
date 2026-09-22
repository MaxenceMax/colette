import 'package:colette/features/dashboard/domain/entities/feeding_age_band.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'feeding_reference.freezed.dart';

/// Repères OMS du jour : tranche d'âge, ml/kg et calcul au poids si pesée.
@freezed
abstract class FeedingReference with _$FeedingReference {
  const factory FeedingReference({
    required int dayOfLife,
    required FeedingAgeBand ageBand,
    required int mlPerKg,
    int? weightGrams,
    int? weightTargetMl,
  }) = _FeedingReference;
}
