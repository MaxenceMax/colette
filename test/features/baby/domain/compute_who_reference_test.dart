import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/who_percentiles.dart';
import 'package:colette/features/baby/domain/use_cases/compute_who_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeWhoReference();
  final birth = DateTime(2026, 9, 1);

  WhoPercentiles at(GrowthMetric metric, BabySex sex, DateTime day) => compute(
    metric: metric,
    sex: sex,
    birthDate: birth,
    from: day,
    to: day,
  ).single;

  (int, int, int) values(WhoPercentiles p) => (p.p3, p.p50, p.p97);

  test('poids, garçon à la naissance : grammes des tables OMS', () {
    final p = at(GrowthMetric.weight, BabySex.male, birth);
    expect(p.ageDays, 0);
    expect(p.date, birth);
    expect(values(p), (2507, 3346, 4350));
  });

  test('poids, fille à 30 jours', () {
    final p = at(GrowthMetric.weight, BabySex.female, DateTime(2026, 10, 1));
    expect(p.ageDays, 30);
    expect(values(p), (3203, 4172, 5371));
  });

  test('taille en millimètres : garçon à la naissance, fille à 30 jours', () {
    expect(values(at(GrowthMetric.length, BabySex.male, birth)), (
      463,
      499,
      534,
    ));
    expect(
      values(at(GrowthMetric.length, BabySex.female, DateTime(2026, 10, 1))),
      (500, 536, 573),
    );
  });

  test('périmètre crânien en millimètres : garçon à la naissance, fille à 730 jours', () {
    expect(values(at(GrowthMetric.headCircumference, BabySex.male, birth)), (
      321,
      345,
      369,
    ));
    final last = compute(
      metric: GrowthMetric.headCircumference,
      sex: BabySex.female,
      birthDate: birth,
      from: DateTime(2028, 8, 1),
      to: DateTime(2028, 12, 1),
    ).last;
    expect(last.ageDays, ComputeWhoReference.maxAgeDays);
    expect(values(last), (446, 472, 498));
  });

  test('un point par jour civil entre from et to inclus', () {
    final points = compute(
      metric: GrowthMetric.length,
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
      metric: GrowthMetric.weight,
      sex: BabySex.female,
      birthDate: birth,
      from: DateTime(2026, 8, 25),
      to: DateTime(2028, 12, 1),
    );
    expect(points.first.ageDays, 0);
    expect(points.last.ageDays, ComputeWhoReference.maxAgeDays);
    expect(points.last.p50, 11474);
  });

  test('période entièrement hors table : aucun point', () {
    expect(
      compute(
        metric: GrowthMetric.headCircumference,
        sex: BabySex.male,
        birthDate: birth,
        from: DateTime(2029),
        to: DateTime(2029, 2),
      ),
      isEmpty,
    );
  });
}
