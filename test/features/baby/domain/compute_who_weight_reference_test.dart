import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/use_cases/compute_who_weight_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeWhoWeightReference();
  final birth = DateTime(2026, 9, 1);

  test('garçon à la naissance : P3, médiane et P97 des tables OMS', () {
    final points = compute(
      sex: BabySex.male,
      birthDate: birth,
      from: birth,
      to: birth,
    );
    expect(points, hasLength(1));
    expect(points.single.ageDays, 0);
    expect(points.single.date, birth);
    expect(points.single.p3Grams, 2507);
    expect(points.single.p50Grams, 3346);
    expect(points.single.p97Grams, 4350);
  });

  test('fille : table distincte de celle des garçons', () {
    final atBirth = compute(
      sex: BabySex.female,
      birthDate: birth,
      from: birth,
      to: birth,
    ).single;
    expect(
      (atBirth.p3Grams, atBirth.p50Grams, atBirth.p97Grams),
      (2440, 3232, 4166),
    );
    final day30 = DateTime(2026, 10, 1);
    final month = compute(
      sex: BabySex.female,
      birthDate: birth,
      from: day30,
      to: day30,
    ).single;
    expect(month.ageDays, 30);
    expect((month.p3Grams, month.p50Grams, month.p97Grams), (3203, 4172, 5371));
  });

  test('un point par jour civil entre from et to inclus', () {
    final points = compute(
      sex: BabySex.male,
      birthDate: birth,
      from: DateTime(2026, 9, 10, 18),
      to: DateTime(2026, 9, 14, 8),
    );
    expect(points.map((p) => p.ageDays), [9, 10, 11, 12, 13]);
    expect(points.first.date, DateTime(2026, 9, 10));
    expect(points.last.date, DateTime(2026, 9, 14));
  });

  test('borne à la naissance et à 730 jours', () {
    final points = compute(
      sex: BabySex.female,
      birthDate: birth,
      from: DateTime(2026, 8, 25),
      to: DateTime(2028, 12, 1),
    );
    expect(points.first.ageDays, 0);
    expect(points.last.ageDays, ComputeWhoWeightReference.maxAgeDays);
    expect(points.last.p50Grams, 11474);
  });

  test('période entièrement hors table : aucun point', () {
    expect(
      compute(
        sex: BabySex.male,
        birthDate: birth,
        from: DateTime(2029),
        to: DateTime(2029, 2),
      ),
      isEmpty,
    );
  });
}
