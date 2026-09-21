import 'dart:math';

/// Génère et valide les codes foyer : 8 caractères, sans O/0 ni I/1.
class HouseholdCodeGenerator {
  HouseholdCodeGenerator([Random? random])
    : _random = random ?? Random.secure();

  static const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const length = 8;

  final Random _random;

  String generate() => List.generate(
    length,
    (_) => alphabet[_random.nextInt(alphabet.length)],
  ).join();

  /// Majuscules, sans espaces.
  static String normalize(String input) =>
      input.replaceAll(' ', '').toUpperCase();

  static bool isValid(String code) =>
      code.length == length && code.split('').every(alphabet.contains);
}
