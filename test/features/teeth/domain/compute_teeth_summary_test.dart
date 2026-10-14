import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/reference/tooth_schedule.dart';
import 'package:colette/features/teeth/domain/use_cases/compute_teeth_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  const compute = ComputeTeethSummary();
  final day = DateTime(2027, 3, 1, 12);

  Map<ToothId, ToothRecord> noted(Iterable<ToothRecord> records) => {
    for (final record in records) record.toothId: record,
  };

  List<(Dentition, ToothArch, ToothKind)> groups(Map<ToothId, ToothRecord> r) =>
      [for (final g in compute(r).next) (g.dentition, g.arch, g.kind)];

  test('à la naissance : incisives centrales du bas puis du haut', () {
    final summary = compute(const {});
    expect(summary.inMouth, 0);
    expect(summary.next, [
      (
        dentition: Dentition.primary,
        arch: ToothArch.lower,
        kind: ToothKind.centralIncisor,
        eruption: (from: 6, to: 10, unit: AgeUnit.months),
      ),
      (
        dentition: Dentition.primary,
        arch: ToothArch.upper,
        kind: ToothKind.centralIncisor,
        eruption: (from: 8, to: 12, unit: AgeUnit.months),
      ),
    ]);
  });

  test('un groupe reste attendu tant qu\'une de ses deux dents manque', () {
    final records = noted([makeTooth(71, eruptedAt: day)]);
    expect(compute(records).inMouth, 1);
    expect(groups(records).first, (
      Dentition.primary,
      ToothArch.lower,
      ToothKind.centralIncisor,
    ));
  });

  test('les deux incisives centrales du bas sorties : groupes suivants', () {
    final records = noted([
      makeTooth(71, eruptedAt: day),
      makeTooth(81, eruptedAt: day),
    ]);
    expect(groups(records), [
      (Dentition.primary, ToothArch.upper, ToothKind.centralIncisor),
      (Dentition.primary, ToothArch.upper, ToothKind.lateralIncisor),
    ]);
  });

  test('une dent tombée ne compte pas en bouche', () {
    final records = noted([
      makeTooth(71, eruptedAt: day, lostAt: DateTime(2033, 5, 2, 12)),
      makeTooth(81, eruptedAt: day),
    ]);
    expect(compute(records).inMouth, 1);
  });

  test('passe aux définitives quand les 20 dents de lait sont notées', () {
    final records = noted([
      for (final id in ToothId.primaryAll) makeTooth(id.value, eruptedAt: day),
    ]);
    expect(compute(records).inMouth, 20);
    // À 6-7 ans ex æquo : le bas avant le haut, puis du milieu vers le fond.
    expect(groups(records), [
      (Dentition.permanent, ToothArch.lower, ToothKind.centralIncisor),
      (Dentition.permanent, ToothArch.lower, ToothKind.firstMolar),
    ]);
  });

  test('plus de groupe quand toutes les dents sont notées', () {
    final records = noted([
      for (final id in [...ToothId.primaryAll, ...ToothId.permanentAll])
        makeTooth(id.value, eruptedAt: day),
    ]);
    expect(compute(records).next, isEmpty);
  });
}
