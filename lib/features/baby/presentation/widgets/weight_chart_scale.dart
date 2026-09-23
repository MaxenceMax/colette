import 'package:colette/features/baby/domain/entities/weight_entry.dart';

/// Échelle de la courbe de poids : période couverte et graduations en grammes.
class WeightChartScale {
  const WeightChartScale._({
    required this.origin,
    required this.minX,
    required this.maxX,
    required this.minGrams,
    required this.maxGrams,
    required this.stepGrams,
  });

  /// Construit l'échelle de [weights], qui ne doit pas être vide ;
  /// [extraGrams] élargit l'axe vertical (courbes de référence).
  factory WeightChartScale.fromWeights(
    List<WeightEntry> weights, {
    Iterable<int> extraGrams = const [],
  }) {
    assert(weights.isNotEmpty, 'Aucune pesée à tracer');
    final dates = weights.map((w) => w.measuredAt).toList()..sort();
    final grams = [...weights.map((w) => w.grams), ...extraGrams];
    final low = grams.reduce((a, b) => a < b ? a : b);
    final high = grams.reduce((a, b) => a > b ? a : b);
    final step = _steps.firstWhere(
      (step) => _span(low, high, step).intervals <= maxIntervals,
      orElse: () => _steps.last,
    );
    final span = _span(low, high, step);
    final lastX = _daysBetween(dates.first, dates.last);
    return WeightChartScale._(
      origin: dates.first,
      minX: lastX == 0 ? -_singlePaddingDays : 0,
      maxX: lastX == 0 ? _singlePaddingDays : lastX,
      minGrams: span.min,
      maxGrams: span.max,
      stepGrams: step,
    );
  }

  /// Nombre maximal d'intervalles entre graduations.
  static const maxIntervals = 4;

  static const _minIntervals = 2;
  static const _steps = [100, 250, 500, 1000, 2000];

  /// Marge de part et d'autre d'une pesée unique, en jours.
  static const _singlePaddingDays = 1.0;

  /// Date de la première pesée, abscisse 0.
  final DateTime origin;

  /// Bornes de l'axe horizontal, en jours depuis [origin].
  final double minX;
  final double maxX;

  final int minGrams;
  final int maxGrams;
  final int stepGrams;

  /// Graduations, de la plus basse à la plus haute.
  List<int> get ticks => [
    for (var g = minGrams; g <= maxGrams; g += stepGrams) g,
  ];

  /// Pas des dates en abscisse : tombe sur la première et la dernière pesée,
  /// ou sur la pesée unique entre ses marges.
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
