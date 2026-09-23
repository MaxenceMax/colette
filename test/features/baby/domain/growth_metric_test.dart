import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final full = GrowthMeasurement(
    id: 'a',
    measuredAt: DateTime(2026, 9, 2),
    grams: 3200,
    lengthMm: 520,
    headCircumferenceMm: 350,
  );
  final weightOnly = GrowthMeasurement(
    id: 'b',
    measuredAt: DateTime(2026, 9, 10),
    grams: 3470,
  );
  final lengthOnly = GrowthMeasurement(
    id: 'c',
    measuredAt: DateTime(2026, 9, 14),
    lengthMm: 540,
  );

  test('valueOf lit la grandeur demandée', () {
    expect(GrowthMetric.weight.valueOf(full), 3200);
    expect(GrowthMetric.length.valueOf(full), 520);
    expect(GrowthMetric.headCircumference.valueOf(full), 350);
    expect(GrowthMetric.length.valueOf(weightOnly), isNull);
  });

  test('seriesOf garde les mesures de la grandeur, de la plus ancienne à la plus récente', () {
    final series = GrowthMetric.length.seriesOf([lengthOnly, weightOnly, full]);
    expect(series, [
      (at: DateTime(2026, 9, 2), value: 520),
      (at: DateTime(2026, 9, 14), value: 540),
    ]);
  });

  test('latestOf ignore les mesures sans la grandeur', () {
    final measurements = [lengthOnly, weightOnly, full];
    expect(GrowthMetric.weight.latestOf(measurements), weightOnly);
    expect(GrowthMetric.length.latestOf(measurements), lengthOnly);
    expect(GrowthMetric.headCircumference.latestOf([weightOnly]), isNull);
  });

  test('latestOf et seriesOf départagent deux mesures du même jour par id', () {
    final sameDay = DateTime(2026, 9, 20);
    final x = GrowthMeasurement(id: 'x', measuredAt: sameDay, grams: 3100);
    final y = GrowthMeasurement(id: 'y', measuredAt: sameDay, grams: 3300);

    expect(GrowthMetric.weight.latestOf([x, y]), y);
    expect(GrowthMetric.weight.latestOf([y, x]), y);
    expect(GrowthMetric.weight.seriesOf([x, y]).last.value, y.grams);
    expect(GrowthMetric.weight.seriesOf([y, x]).last.value, y.grams);
  });

  test('latestOf et seriesOf gèrent une liste vide', () {
    expect(GrowthMetric.weight.latestOf(const []), isNull);
    expect(GrowthMetric.weight.seriesOf(const []), isEmpty);
  });
}
