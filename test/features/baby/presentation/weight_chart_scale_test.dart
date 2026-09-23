import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/widgets/weight_chart_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WeightEntry weight(DateTime at, int grams) =>
      WeightEntry(id: '$at', measuredAt: at, grams: grams);

  test('arrondit les bornes au pas et garde au plus 4 intervalles', () {
    final scale = WeightChartScale.fromWeights([
      weight(DateTime(2026, 9, 1), 3280),
      weight(DateTime(2026, 9, 20), 4110),
    ]);
    expect(scale.stepGrams, 250);
    expect(scale.minGrams, 3250);
    expect(scale.maxGrams, 4250);
    expect(scale.ticks, [3250, 3500, 3750, 4000, 4250]);
  });

  test('petite variation : au moins deux intervalles de 100 g', () {
    final scale = WeightChartScale.fromWeights([
      weight(DateTime(2026, 9, 1), 3410),
      weight(DateTime(2026, 9, 2), 3430),
    ]);
    expect(scale.stepGrams, 100);
    expect(scale.ticks.length, greaterThanOrEqualTo(3));
    expect(scale.minGrams, lessThanOrEqualTo(3410));
    expect(scale.maxGrams, greaterThanOrEqualTo(3430));
  });

  test('une seule pesée : centrée dans le temps et entourée de marge', () {
    final at = DateTime(2026, 9, 10);
    final scale = WeightChartScale.fromWeights([weight(at, 3500)]);
    expect(scale.xOf(at), 0);
    expect(scale.minX, -1);
    expect(scale.maxX, 1);
    expect(scale.dateInterval, 1);
    expect(3500 - scale.minGrams, scale.maxGrams - 3500);
  });

  test('abscisses en jours depuis la première pesée', () {
    final first = DateTime(2026, 9, 1);
    final last = DateTime(2026, 9, 11);
    final scale = WeightChartScale.fromWeights([
      weight(first, 3000),
      weight(DateTime(2026, 9, 6), 3200),
      weight(last, 3500),
    ]);
    expect(scale.origin, first);
    expect(scale.minX, 0);
    expect(scale.maxX, 10);
    expect(scale.xOf(DateTime(2026, 9, 6, 12)), 5.5);
    expect(scale.xOf(last), 10);
    expect(scale.dateInterval, 10);
  });

  test('grand écart : pas élargi', () {
    final scale = WeightChartScale.fromWeights([
      weight(DateTime(2026, 1, 1), 3000),
      weight(DateTime(2026, 9, 1), 8200),
    ]);
    expect(scale.stepGrams, 2000);
    expect(scale.ticks, [2000, 4000, 6000, 8000, 10000]);
  });

  test('extraGrams élargit l\'axe vertical', () {
    final scale = WeightChartScale.fromWeights(
      [weight(DateTime(2026, 9, 1), 3500)],
      extraGrams: const [2600, 4400],
    );
    expect(scale.minGrams, lessThanOrEqualTo(2600));
    expect(scale.maxGrams, greaterThanOrEqualTo(4400));
  });
}
