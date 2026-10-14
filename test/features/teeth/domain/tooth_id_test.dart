import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  test('décode dentition, arcade, côté et type', () {
    (Dentition, ToothArch, ToothSide, ToothKind) decode(int n) {
      final id = tooth(n);
      return (id.dentition, id.arch, id.side, id.kind);
    }

    expect(decode(51), (
      Dentition.primary,
      ToothArch.upper,
      ToothSide.right,
      ToothKind.centralIncisor,
    ));
    expect(decode(55), (
      Dentition.primary,
      ToothArch.upper,
      ToothSide.right,
      ToothKind.secondMolar,
    ));
    expect(decode(65), (
      Dentition.primary,
      ToothArch.upper,
      ToothSide.left,
      ToothKind.secondMolar,
    ));
    expect(decode(71), (
      Dentition.primary,
      ToothArch.lower,
      ToothSide.left,
      ToothKind.centralIncisor,
    ));
    expect(decode(84), (
      Dentition.primary,
      ToothArch.lower,
      ToothSide.right,
      ToothKind.firstMolar,
    ));
    expect(decode(11), (
      Dentition.permanent,
      ToothArch.upper,
      ToothSide.right,
      ToothKind.centralIncisor,
    ));
    expect(decode(18), (
      Dentition.permanent,
      ToothArch.upper,
      ToothSide.right,
      ToothKind.thirdMolar,
    ));
    expect(decode(24), (
      Dentition.permanent,
      ToothArch.upper,
      ToothSide.left,
      ToothKind.firstPremolar,
    ));
    expect(decode(36), (
      Dentition.permanent,
      ToothArch.lower,
      ToothSide.left,
      ToothKind.firstMolar,
    ));
    expect(decode(48), (
      Dentition.permanent,
      ToothArch.lower,
      ToothSide.right,
      ToothKind.thirdMolar,
    ));
  });

  test('tryParse refuse les numéros hors table', () {
    for (final n in [0, 10, 19, 49, 56, 59, 86, 90, 99, 100, -11]) {
      expect(ToothId.tryParse(n), isNull, reason: '$n');
    }
  });

  test('listes complètes, sans doublon, dans l\'ordre du schéma', () {
    expect(ToothId.primaryAll, hasLength(20));
    expect(ToothId.primaryAll.toSet(), hasLength(20));
    expect(ToothId.permanentAll, hasLength(32));
    expect(ToothId.permanentAll.toSet(), hasLength(32));
    expect(
      ToothId.primaryAll.every((id) => id.dentition == Dentition.primary),
      isTrue,
    );
    expect(
      ToothId.permanentAll.every((id) => id.dentition == Dentition.permanent),
      isTrue,
    );
    List<int> numbers(Iterable<ToothId> ids) => [
      for (final id in ids) id.value,
    ];
    expect(numbers(ToothId.primaryAll.take(5)), [55, 54, 53, 52, 51]);
    expect(numbers(ToothId.primaryAll.skip(5).take(5)), [61, 62, 63, 64, 65]);
    expect(numbers(ToothId.primaryAll.skip(10).take(5)), [85, 84, 83, 82, 81]);
    expect(numbers(ToothId.primaryAll.skip(15)), [71, 72, 73, 74, 75]);
    expect(numbers(ToothId.permanentAll.take(8)), [
      18,
      17,
      16,
      15,
      14,
      13,
      12,
      11,
    ]);
    expect(numbers(ToothId.permanentAll.skip(8).take(8)), [
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
    ]);
    expect(numbers(ToothId.permanentAll.skip(16).take(8)), [
      48,
      47,
      46,
      45,
      44,
      43,
      42,
      41,
    ]);
    expect(numbers(ToothId.permanentAll.skip(24)), [
      31,
      32,
      33,
      34,
      35,
      36,
      37,
      38,
    ]);
    expect(ToothId.all(Dentition.primary), ToothId.primaryAll);
    expect(ToothId.all(Dentition.permanent), ToothId.permanentAll);
  });

  test('chaque dent listée se relit à l\'identique', () {
    for (final id in [...ToothId.primaryAll, ...ToothId.permanentAll]) {
      expect(ToothId.tryParse(id.value), id);
    }
  });
}
