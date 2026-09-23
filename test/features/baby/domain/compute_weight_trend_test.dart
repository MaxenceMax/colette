import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/domain/entities/weight_trend.dart';
import 'package:colette/features/baby/domain/use_cases/compute_weight_trend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeWeightTrend();

  WeightEntry weight(String id, DateTime at, int grams) =>
      WeightEntry(id: id, measuredAt: at, grams: grams);

  test('aucune pesée : pas de tendance', () {
    expect(compute(const []), isNull);
  });

  test('une seule pesée : dernière pesée sans précédente', () {
    final only = weight('a', DateTime(2026, 9, 10), 3400);
    final trend = compute([only])!;
    expect(trend.latest, only);
    expect(trend.previous, isNull);
    expect(trend.deltaGrams, isNull);
    expect(trend.days, isNull);
    expect(trend.gramsPerDay, isNull);
  });

  test('compare les deux pesées les plus récentes, quel que soit l\'ordre', () {
    final trend = compute([
      weight('old', DateTime(2026, 9, 2), 3200),
      weight('last', DateTime(2026, 9, 14), 3650),
      weight('prev', DateTime(2026, 9, 10), 3470),
    ])!;
    expect(trend.latest.id, 'last');
    expect(trend.previous!.id, 'prev');
    expect(trend.deltaGrams, 180);
    expect(trend.days, 4);
    expect(trend.gramsPerDay, 45);
  });

  test('une perte donne un écart négatif', () {
    final trend = compute([
      weight('a', DateTime(2026, 9, 1), 3500),
      weight('b', DateTime(2026, 9, 4), 3290),
    ])!;
    expect(trend.deltaGrams, -210);
    expect(trend.gramsPerDay, -70);
  });

  test('ignore une autre pesée du même jour que la dernière', () {
    final trend = compute([
      weight('a', DateTime(2026, 9, 1), 3500),
      weight('b', DateTime(2026, 9, 5), 3600),
      weight('c', DateTime(2026, 9, 5, 18), 3620),
    ])!;
    expect(trend.latest.id, 'c');
    expect(trend.previous!.id, 'a');
    expect(trend.days, 4);
    expect(trend.gramsPerDay, 30);
  });

  test('toutes les pesées le même jour : pas de précédente', () {
    final trend = compute([
      weight('a', DateTime(2026, 9, 5, 8), 3500),
      weight('b', DateTime(2026, 9, 5, 18), 3520),
    ])!;
    expect(trend.latest.id, 'b');
    expect(trend.previous, isNull);
  });

  test('arrondit le gain journalier', () {
    final trend = compute([
      weight('a', DateTime(2026, 9, 1), 3500),
      weight('b', DateTime(2026, 9, 4), 3600),
    ])!;
    expect(trend.gramsPerDay, 33);
  });

  test('compte les jours civils malgré le changement d\'heure', () {
    final trend = compute([
      weight('a', DateTime(2026, 10, 24), 3500),
      weight('b', DateTime(2026, 10, 26), 3560),
    ])!;
    expect(trend.days, 2);
  });
}
