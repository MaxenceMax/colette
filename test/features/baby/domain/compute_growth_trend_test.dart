import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/growth_trend.dart';
import 'package:colette/features/baby/domain/use_cases/compute_growth_trend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeGrowthTrend();

  GrowthMeasurement weight(String id, DateTime at, int grams) =>
      GrowthMeasurement(id: id, measuredAt: at, grams: grams);

  test('aucune mesure : pas de tendance', () {
    expect(compute(GrowthMetric.weight, const []), isNull);
  });

  test('une seule pesée : dernière valeur sans précédente', () {
    final trend = compute(GrowthMetric.weight, [
      weight('a', DateTime(2026, 9, 10), 3400),
    ])!;
    expect(trend.metric, GrowthMetric.weight);
    expect(trend.latestValue, 3400);
    expect(trend.latestAt, DateTime(2026, 9, 10));
    expect(trend.previousValue, isNull);
    expect(trend.delta, isNull);
    expect(trend.days, isNull);
    expect(trend.perDay, isNull);
  });

  test('compare les deux pesées les plus récentes, quel que soit l\'ordre', () {
    final trend = compute(GrowthMetric.weight, [
      weight('old', DateTime(2026, 9, 2), 3200),
      weight('last', DateTime(2026, 9, 14), 3650),
      weight('prev', DateTime(2026, 9, 10), 3470),
    ])!;
    expect(trend.latestValue, 3650);
    expect(trend.previousValue, 3470);
    expect(trend.delta, 180);
    expect(trend.days, 4);
    expect(trend.perDay, 45);
  });

  test('une perte donne un écart négatif', () {
    final trend = compute(GrowthMetric.weight, [
      weight('a', DateTime(2026, 9, 1), 3500),
      weight('b', DateTime(2026, 9, 4), 3290),
    ])!;
    expect(trend.delta, -210);
    expect(trend.perDay, -70);
  });

  test('ignore une autre mesure du même jour que la dernière', () {
    final trend = compute(GrowthMetric.weight, [
      weight('a', DateTime(2026, 9, 1), 3500),
      weight('b', DateTime(2026, 9, 5), 3600),
      weight('c', DateTime(2026, 9, 5, 18), 3620),
    ])!;
    expect(trend.latestValue, 3620);
    expect(trend.previousValue, 3500);
    expect(trend.days, 4);
    expect(trend.perDay, 30);
  });

  test('toutes les mesures le même jour : pas de précédente', () {
    final trend = compute(GrowthMetric.weight, [
      weight('a', DateTime(2026, 9, 5, 8), 3500),
      weight('b', DateTime(2026, 9, 5, 18), 3520),
    ])!;
    expect(trend.latestValue, 3520);
    expect(trend.previousValue, isNull);
  });

  test('arrondit le gain journalier', () {
    final trend = compute(GrowthMetric.weight, [
      weight('a', DateTime(2026, 9, 1), 3500),
      weight('b', DateTime(2026, 9, 4), 3600),
    ])!;
    expect(trend.perDay, 33);
  });

  test('compte les jours civils malgré le changement d\'heure', () {
    // En Europe/Paris, cet intervalle ne fait que 47 h (passage à l'heure
    // d'été) : un calcul naïf sur la durée donnerait 1 jour au lieu de 2.
    final trend = compute(GrowthMetric.weight, [
      weight('a', DateTime(2026, 3, 28), 3500),
      weight('b', DateTime(2026, 3, 30), 3560),
    ])!;
    expect(trend.days, 2);
  });

  test('plusieurs mesures le jour précédent : garde la plus récente', () {
    final trend = compute(GrowthMetric.weight, [
      weight('a', DateTime(2026, 9, 4, 8), 3500),
      weight('b', DateTime(2026, 9, 4, 20), 3520),
      weight('c', DateTime(2026, 9, 5), 3600),
    ])!;
    expect(trend.previousValue, 3520);
  });

  test('taille : ignore les mesures sans taille', () {
    final measurements = [
      GrowthMeasurement(
        id: 'a',
        measuredAt: DateTime(2026, 9, 2),
        grams: 3200,
        lengthMm: 520,
      ),
      weight('b', DateTime(2026, 9, 10), 3470),
      GrowthMeasurement(
        id: 'c',
        measuredAt: DateTime(2026, 9, 20),
        lengthMm: 545,
      ),
    ];
    final trend = compute(GrowthMetric.length, measurements)!;
    expect(trend.metric, GrowthMetric.length);
    expect(trend.latestValue, 545);
    expect(trend.previousValue, 520);
    expect(trend.previousAt, DateTime(2026, 9, 2));
    expect(trend.delta, 25);
    expect(trend.days, 18);
  });

  test('périmètre absent de toutes les mesures : pas de tendance', () {
    expect(
      compute(GrowthMetric.headCircumference, [
        weight('a', DateTime(2026, 9, 2), 3200),
      ]),
      isNull,
    );
  });

  group('GrowthTrend', () {
    test(
      'previousAt le même jour civil que latestAt : jours nuls, pas de perDay',
      () {
        final trend = GrowthTrend(
          metric: GrowthMetric.weight,
          latestValue: 3600,
          latestAt: DateTime(2026, 9, 5, 18),
          previousValue: 3500,
          previousAt: DateTime(2026, 9, 5, 8),
        );
        expect(trend.days, 0);
        expect(trend.perDay, isNull);
      },
    );
  });
}
