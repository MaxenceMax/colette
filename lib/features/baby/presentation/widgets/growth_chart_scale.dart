import 'package:colette/features/baby/domain/entities/growth_metric.dart';

/// Échelle d'une courbe de croissance : période couverte et graduations, en
/// grammes (poids) ou en millimètres (taille, périmètre crânien).
class GrowthChartScale {
  const GrowthChartScale._({
    required this.origin,
    required this.minX,
    required this.maxX,
    required this.minValue,
    required this.maxValue,
    required this.step,
  });

  /// Construit l'échelle de [points], qui ne doit pas être vide ;
  /// [extraValues] élargit l'axe vertical (courbes de référence).
  factory GrowthChartScale.fromPoints(
    List<GrowthPoint> points, {
    required GrowthMetric metric,
    Iterable<int> extraValues = const [],
  }) {
    assert(points.isNotEmpty, 'Aucune mesure à tracer');
    final dates = points.map((p) => p.at).toList()..sort();
    final values = [...points.map((p) => p.value), ...extraValues];
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final steps = stepsFor(metric);
    final step = steps.firstWhere(
      (step) => _span(low, high, step).intervals <= maxIntervals,
      orElse: () => steps.last,
    );
    final span = _span(low, high, step);
    final lastX = _daysBetween(dates.first, dates.last);
    return GrowthChartScale._(
      origin: dates.first,
      minX: lastX == 0 ? -_singlePaddingDays : 0,
      maxX: lastX == 0 ? _singlePaddingDays : lastX,
      minValue: span.min,
      maxValue: span.max,
      step: step,
    );
  }

  /// Nombre maximal d'intervalles entre graduations.
  static const maxIntervals = 4;

  static const _minIntervals = 2;

  /// Marge de part et d'autre d'une mesure unique, en jours.
  static const _singlePaddingDays = 1.0;

  /// Pas de graduation possibles, du plus fin au plus large.
  static List<int> stepsFor(GrowthMetric metric) => switch (metric) {
    GrowthMetric.weight => const [100, 250, 500, 1000, 2000],
    GrowthMetric.length ||
    GrowthMetric.headCircumference => const [5, 10, 20, 50, 100],
  };

  /// Date de la première mesure, abscisse 0.
  final DateTime origin;

  /// Bornes de l'axe horizontal, en jours depuis [origin].
  final double minX;
  final double maxX;

  /// Bornes et pas de l'axe vertical, dans l'unité de la grandeur.
  final int minValue;
  final int maxValue;
  final int step;

  /// Graduations, de la plus basse à la plus haute.
  List<int> get ticks => [for (var v = minValue; v <= maxValue; v += step) v];

  /// Pas des dates en abscisse : tombe sur la première et la dernière mesure,
  /// ou sur la mesure unique entre ses marges.
  double get dateInterval => minX < 0 ? -minX : maxX;

  /// Abscisse de [at], en jours (fractionnaires) depuis [origin].
  double xOf(DateTime at) => _daysBetween(origin, at);

  static double _daysBetween(DateTime from, DateTime to) =>
      to.difference(from).inMinutes / Duration.minutesPerDay;

  /// Bornes arrondies à [step], élargies alternativement vers le bas et le haut
  /// jusqu'à [_minIntervals] intervalles.
  static ({int min, int max, int intervals}) _span(
    int low,
    int high,
    int step,
  ) {
    var min = (low ~/ step) * step;
    var max = ((high + step - 1) ~/ step) * step;
    var extendDown = true;
    while ((max - min) ~/ step < _minIntervals) {
      if (extendDown && min - step > 0) {
        min -= step;
      } else {
        max += step;
      }
      extendDown = !extendDown;
    }
    return (min: min, max: max, intervals: (max - min) ~/ step);
  }
}
