import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/reference/tooth_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  test(
    'chaque dent a ses repères ; chute pour les dents de lait seulement',
    () {
      for (final id in ToothId.primaryAll) {
        expect(toothReferenceOf(id).shedding, isNotNull, reason: '${id.value}');
      }
      for (final id in ToothId.permanentAll) {
        expect(toothReferenceOf(id).shedding, isNull, reason: '${id.value}');
      }
    },
  );

  test('valeurs du tableau ADA', () {
    expect(toothReferenceOf(tooth(71)).eruption, (
      from: 6,
      to: 10,
      unit: AgeUnit.months,
    ));
    expect(toothReferenceOf(tooth(51)).eruption, (
      from: 8,
      to: 12,
      unit: AgeUnit.months,
    ));
    expect(toothReferenceOf(tooth(51)).shedding, (
      from: 6,
      to: 7,
      unit: AgeUnit.years,
    ));
    expect(toothReferenceOf(tooth(83)).shedding, (
      from: 9,
      to: 12,
      unit: AgeUnit.years,
    ));
    expect(toothReferenceOf(tooth(65)).eruption, (
      from: 25,
      to: 33,
      unit: AgeUnit.months,
    ));
    expect(toothReferenceOf(tooth(43)).eruption, (
      from: 9,
      to: 10,
      unit: AgeUnit.years,
    ));
    expect(toothReferenceOf(tooth(17)).eruption, (
      from: 12,
      to: 13,
      unit: AgeUnit.years,
    ));
    expect(toothReferenceOf(tooth(38)).eruption, (
      from: 17,
      to: 21,
      unit: AgeUnit.years,
    ));
  });

  test('droite et gauche ont les mêmes repères', () {
    expect(toothReferenceOf(tooth(54)), toothReferenceOf(tooth(64)));
    expect(toothReferenceOf(tooth(36)), toothReferenceOf(tooth(46)));
  });

  test('fromMonths convertit les années', () {
    expect((from: 6, to: 10, unit: AgeUnit.months).fromMonths, 6);
    expect((from: 6, to: 7, unit: AgeUnit.years).fromMonths, 72);
  });
}
