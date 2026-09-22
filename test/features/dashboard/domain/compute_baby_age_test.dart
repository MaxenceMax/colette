import 'package:colette/features/dashboard/domain/entities/baby_age.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_baby_age.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeBabyAge();
  final birth = DateTime(2026, 9, 1, 10);

  test('moins de 14 jours : en jours', () {
    expect(
      compute(birthDate: birth, now: DateTime(2026, 9, 1, 12)),
      const BabyAge(unit: BabyAgeUnit.days, count: 0),
    );
    expect(
      compute(birthDate: birth, now: DateTime(2026, 9, 14, 8)),
      const BabyAge(unit: BabyAgeUnit.days, count: 13),
    );
  });

  test('jours civils, insensible au changement d\'heure (DST)', () {
    // Passage à l'heure d'été le 29 mars 2026 entre les deux dates.
    expect(
      compute(birthDate: DateTime(2026, 3, 20), now: DateTime(2026, 3, 30, 12)),
      const BabyAge(unit: BabyAgeUnit.days, count: 10),
    );
  });

  test('de 14 jours à 2 mois : en semaines', () {
    expect(
      compute(birthDate: birth, now: DateTime(2026, 9, 15)),
      const BabyAge(unit: BabyAgeUnit.weeks, count: 2),
    );
    expect(
      compute(birthDate: birth, now: DateTime(2026, 10, 30)),
      const BabyAge(unit: BabyAgeUnit.weeks, count: 8),
    );
  });

  test('ensuite : en mois civils', () {
    expect(
      compute(birthDate: birth, now: DateTime(2026, 11, 1)),
      const BabyAge(unit: BabyAgeUnit.months, count: 2),
    );
    expect(
      compute(birthDate: birth, now: DateTime(2026, 11, 30)),
      const BabyAge(unit: BabyAgeUnit.months, count: 2),
    );
    expect(
      compute(birthDate: birth, now: DateTime(2027, 3, 1)),
      const BabyAge(unit: BabyAgeUnit.months, count: 6),
    );
  });
}
