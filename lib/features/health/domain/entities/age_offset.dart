import 'dart:math' as math;

/// Unité d'un [AgeOffset].
enum AgeUnit { days, months }

/// Âge depuis la naissance, en jours civils ou en mois calendaires.
final class AgeOffset {
  const AgeOffset.days(this.value) : unit = AgeUnit.days;
  const AgeOffset.months(this.value) : unit = AgeUnit.months;

  final int value;
  final AgeUnit unit;

  /// Minuit du jour où l'enfant né le [birthDate] atteint cet âge. En mois,
  /// le jour est borné à la fin du mois (31 janvier + 1 mois = 28 ou 29 février).
  DateTime from(DateTime birthDate) => switch (unit) {
    AgeUnit.days => DateTime(
      birthDate.year,
      birthDate.month,
      birthDate.day + value,
    ),
    AgeUnit.months => _addMonths(birthDate, value),
  };

  static DateTime _addMonths(DateTime birth, int months) {
    final lastDay = DateTime(birth.year, birth.month + months + 1, 0).day;
    return DateTime(
      birth.year,
      birth.month + months,
      math.min(birth.day, lastDay),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AgeOffset && other.value == value && other.unit == unit;

  @override
  int get hashCode => Object.hash(value, unit);
}
