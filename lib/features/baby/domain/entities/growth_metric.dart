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

  /// Points des mesures qui contiennent cette grandeur, triés par [_compare] (ordre déterministe même à date égale).
  List<GrowthPoint> seriesOf(Iterable<GrowthMeasurement> measurements) {
    final withValue = measurements.where((m) => valueOf(m) != null).toList()
      ..sort(_compare);
    return [for (final m in withValue) (at: m.measuredAt, value: valueOf(m)!)];
  }

  /// Mesure la plus récente qui contient cette grandeur selon [_compare], ou `null`.
  GrowthMeasurement? latestOf(Iterable<GrowthMeasurement> measurements) {
    final withValue = measurements.where((m) => valueOf(m) != null).toList()
      ..sort(_compare);
    return withValue.isEmpty ? null : withValue.last;
  }

  /// Ordre déterministe des mesures : par [GrowthMeasurement.measuredAt], puis par `id` pour départager celles du même jour.
  static int _compare(GrowthMeasurement a, GrowthMeasurement b) {
    final byDate = a.measuredAt.compareTo(b.measuredAt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }
}
