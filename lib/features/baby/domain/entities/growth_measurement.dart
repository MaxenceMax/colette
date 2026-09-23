import 'package:freezed_annotation/freezed_annotation.dart';

part 'growth_measurement.freezed.dart';

/// Une mesure de croissance : poids, taille et/ou périmètre crânien relevés
/// le même jour. Au moins une valeur est renseignée.
@freezed
abstract class GrowthMeasurement with _$GrowthMeasurement {
  const factory GrowthMeasurement({
    required String id,
    required DateTime measuredAt,
    int? grams,
    int? lengthMm,
    int? headCircumferenceMm,
  }) = _GrowthMeasurement;
}
