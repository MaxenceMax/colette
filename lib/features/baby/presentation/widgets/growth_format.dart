import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// Textes des valeurs de croissance : « 3650 g », « 54,5 cm ».
abstract final class GrowthFormat {
  static final _centimetres = NumberFormat('0.0', 'fr');

  /// Millimètres en centimètres à une décimale : 545 → « 54,5 ».
  static String centimetres(int mm) => _centimetres.format(mm / 10);

  /// Valeur de [metric] avec son unité.
  static String value(S s, GrowthMetric metric, int value) => switch (metric) {
    GrowthMetric.weight => s.weightGrams(value),
    GrowthMetric.length ||
    GrowthMetric.headCircumference => s.measurementCm(centimetres(value)),
  };

  /// Nom court de [metric], pour le sélecteur.
  static String label(S s, GrowthMetric metric) => switch (metric) {
    GrowthMetric.weight => s.growthMetricWeight,
    GrowthMetric.length => s.growthMetricLength,
    GrowthMetric.headCircumference => s.growthMetricHeadCircumference,
  };

  /// Message quand [metric] n'a jamais été mesurée.
  static String empty(S s, GrowthMetric metric) => switch (metric) {
    GrowthMetric.weight => s.growthEmptyWeight,
    GrowthMetric.length => s.growthEmptyLength,
    GrowthMetric.headCircumference => s.growthEmptyHeadCircumference,
  };

  /// Écart avec signe explicite, sans unité : « +180 », « −0,5 », « 0 ».
  static String signedDelta(GrowthMetric metric, int delta) {
    if (delta == 0) return '0';
    final magnitude = switch (metric) {
      GrowthMetric.weight => '${delta.abs()}',
      GrowthMetric.length ||
      GrowthMetric.headCircumference => centimetres(delta.abs()),
    };
    return delta > 0 ? '+$magnitude' : '−$magnitude';
  }

  /// Valeurs présentes d'une mesure : « 3650 g · 54,5 cm · PC 37,0 cm ».
  static String measurementLine(S s, GrowthMeasurement m) => [
    if (m.grams case final grams?) s.weightGrams(grams),
    if (m.lengthMm case final lengthMm?) s.measurementCm(centimetres(lengthMm)),
    if (m.headCircumferenceMm case final headMm?)
      s.measurementHeadCircumferenceShort(centimetres(headMm)),
  ].join(' · ');
}
