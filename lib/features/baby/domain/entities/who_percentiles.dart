import 'package:freezed_annotation/freezed_annotation.dart';

part 'who_percentiles.freezed.dart';

/// Valeurs de référence OMS d'un jour de vie : 3e, 50e et 97e percentiles,
/// en grammes (poids) ou en millimètres (taille, périmètre crânien).
@freezed
abstract class WhoPercentiles with _$WhoPercentiles {
  const factory WhoPercentiles({
    required int ageDays,
    required DateTime date,
    required int p3,
    required int p50,
    required int p97,
  }) = _WhoPercentiles;
}
