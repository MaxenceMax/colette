import 'package:colette/features/baby/domain/entities/growth_measurement.dart';

/// Point d'une série de croissance : date et valeur (grammes ou millimètres).
typedef GrowthPoint = ({DateTime at, int value});

/// Grandeur suivie : poids en grammes, taille et périmètre crânien en millimètres.
enum GrowthMetric {
  weight,
  length,
  headCircumference;

  /// Valeur de [measurement] pour cette grandeur, `null` si elle n'a pas été mesurée.
  int? valueOf(GrowthMeasurement measurement) => switch (this) {
    GrowthMetric.weight => measurement.grams,
    GrowthMetric.length => measurement.lengthMm,
    GrowthMetric.headCircumference => measurement.headCircumferenceMm,
  };

  /// Points des mesures qui contiennent cette grandeur, du plus ancien au plus récent.
  List<GrowthPoint> seriesOf(Iterable<GrowthMeasurement> measurements) => [
    for (final m in measurements)
      if (valueOf(m) case final value?) (at: m.measuredAt, value: value),
  ]..sort((a, b) => a.at.compareTo(b.at));

  /// Mesure la plus récente qui contient cette grandeur, ou `null`.
  GrowthMeasurement? latestOf(Iterable<GrowthMeasurement> measurements) {
    GrowthMeasurement? latest;
    for (final m in measurements) {
      if (valueOf(m) == null) continue;
      if (latest == null || m.measuredAt.isAfter(latest.measuredAt)) {
        latest = m;
      }
    }
    return latest;
  }
}
