import 'dart:math';

import 'package:colette/features/household/domain/household_code_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('génère 8 caractères de l\'alphabet sans ambiguïté', () {
    final code = HouseholdCodeGenerator().generate();
    expect(code.length, 8);
    expect(
      code.split('').every(HouseholdCodeGenerator.alphabet.contains),
      isTrue,
    );
  });

  test('est déterministe avec un Random seedé', () {
    final a = HouseholdCodeGenerator(Random(42)).generate();
    final b = HouseholdCodeGenerator(Random(42)).generate();
    expect(a, b);
  });

  test('isValid accepte un code généré et refuse les autres', () {
    expect(
      HouseholdCodeGenerator.isValid(HouseholdCodeGenerator().generate()),
      isTrue,
    );
    expect(HouseholdCodeGenerator.isValid('ABCD'), isFalse);
    expect(HouseholdCodeGenerator.isValid('ABCDEFG0'), isFalse);
    expect(HouseholdCodeGenerator.isValid('abcdefgh'), isFalse);
  });

  test('normalize met en majuscules et retire les espaces', () {
    expect(HouseholdCodeGenerator.normalize(' abcd efgh '), 'ABCDEFGH');
  });
}
