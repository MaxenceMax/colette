import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/presentation/widgets/growth_chart_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GrowthPoint point(DateTime at, int value) => (at: at, value: value);

  GrowthChartScale weight(
    List<GrowthPoint> points, {
    List<int> extra = const [],
  }) => GrowthChartScale.fromPoints(
    points,
    metric: GrowthMetric.weight,
    extraValues: extra,
  );

  test('poids : arrondit les bornes au pas et garde au plus 4 intervalles', () {
    final scale = weight([
      point(DateTime(2026, 9, 1), 3280),
      point(DateTime(2026, 9, 20), 4110),
    ]);
    expect(scale.step, 250);
    expect(scale.minValue, 3250);
    expect(scale.maxValue, 4250);
    expect(scale.ticks, [3250, 3500, 3750, 4000, 4250]);
  });

  test('poids : petite variation, au moins deux intervalles de 100 g', () {
    final scale = weight([
      point(DateTime(2026, 9, 1), 3410),
      point(DateTime(2026, 9, 2), 3430),
    ]);
    expect(scale.step, 100);
    expect(scale.ticks.length, greaterThanOrEqualTo(3));
    expect(scale.minValue, lessThanOrEqualTo(3410));
    expect(scale.maxValue, greaterThanOrEqualTo(3430));
  });

  test('une seule mesure : centrée dans le temps et entourée de marge', () {
    final at = DateTime(2026, 9, 10);
    final scale = weight([point(at, 3500)]);
    expect(scale.xOf(at), 0);
    expect(scale.minX, -1);
    expect(scale.maxX, 1);
    expect(scale.dateInterval, 1);
    expect(3500 - scale.minValue, scale.maxValue - 3500);
  });

  test('abscisses en jours depuis la première mesure', () {
    final first = DateTime(2026, 9, 1);
    final last = DateTime(2026, 9, 11);
    final scale = weight([
      point(first, 3000),
      point(DateTime(2026, 9, 6), 3200),
      point(last, 3500),
    ]);
    expect(scale.origin, first);
    expect(scale.minX, 0);
    expect(scale.maxX, 10);
    expect(scale.xOf(DateTime(2026, 9, 6, 12)), 5.5);
    expect(scale.xOf(last), 10);
    expect(scale.dateInterval, 10);
  });

  test('poids : grand écart, pas élargi', () {
    final scale = weight([
      point(DateTime(2026, 1, 1), 3000),
      point(DateTime(2026, 9, 1), 8200),
    ]);
    expect(scale.step, 2000);
    expect(scale.ticks, [2000, 4000, 6000, 8000, 10000]);
  });

  test('extraValues élargit l\'axe vertical', () {
    final scale = weight(
      [point(DateTime(2026, 9, 1), 3500)],
      extra: const [2600, 4400],
    );
    expect(scale.minValue, lessThanOrEqualTo(2600));
    expect(scale.maxValue, greaterThanOrEqualTo(4400));
  });

  test('taille : pas en millimètres', () {
    final scale = GrowthChartScale.fromPoints([
      point(DateTime(2026, 9, 1), 500),
      point(DateTime(2026, 9, 20), 545),
    ], metric: GrowthMetric.length);
    expect(scale.step, 20);
    expect(scale.ticks, [500, 520, 540, 560]);
  });

  test('périmètre : petite variation, pas de 5 mm', () {
    final scale = GrowthChartScale.fromPoints([
      point(DateTime(2026, 9, 1), 345),
      point(DateTime(2026, 9, 8), 350),
    ], metric: GrowthMetric.headCircumference);
    expect(scale.step, 5);
    expect(scale.ticks, [340, 345, 350]);
  });

  test('taille : plusieurs mois avec courbes OMS, pas de 100 mm', () {
    final scale = GrowthChartScale.fromPoints([
      point(DateTime(2026, 3, 1), 460),
      point(DateTime(2026, 9, 1), 720),
    ], metric: GrowthMetric.length);
    expect(scale.step, 100);
    expect(
      scale.ticks.length - 1,
      lessThanOrEqualTo(GrowthChartScale.maxIntervals),
    );
  });
}
