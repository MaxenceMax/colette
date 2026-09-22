import 'package:colette/features/dashboard/domain/entities/feeding_age_band.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeFeedingReference();
  final birth = DateTime(2026, 9, 1, 6);

  test('jour 3 sans pesée : 100 ml/kg, pas de calcul au poids', () {
    final reference = compute(
      birthDate: birth,
      latestWeightGrams: null,
      now: DateTime(2026, 9, 3, 12),
    );
    expect(reference.dayOfLife, 3);
    expect(reference.ageBand, FeedingAgeBand.day3);
    expect(reference.mlPerKg, 100);
    expect(reference.weightGrams, isNull);
    expect(reference.weightTargetMl, isNull);
  });

  test('jour 10 avec 4 200 g : 150 ml/kg, cible au poids 630', () {
    final reference = compute(
      birthDate: birth,
      latestWeightGrams: 4200,
      now: DateTime(2026, 9, 10, 12),
    );
    expect(reference.dayOfLife, 10);
    expect(reference.ageBand, FeedingAgeBand.day6ToMonth1);
    expect(reference.mlPerKg, 150);
    expect(reference.weightGrams, 4200);
    expect(reference.weightTargetMl, 630);
  });

  test('la cible au poids est arrondie à 10 ml', () {
    final reference = compute(
      birthDate: birth,
      latestWeightGrams: 3570,
      now: DateTime(2026, 9, 10, 12),
    );
    // 150 × 3,57 = 535,5 → 540.
    expect(reference.weightTargetMl, 540);
  });
}
