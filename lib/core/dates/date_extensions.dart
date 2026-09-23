/// Aides sur les jours civils (heure locale de l'appareil).
extension DateOnlyX on DateTime {
  /// Minuit du même jour.
  DateTime get dateOnly => DateTime(year, month, day);

  /// Minuit du lendemain.
  DateTime get startOfNextDay => DateTime(year, month, day + 1);

  /// Minuit de la veille.
  DateTime get startOfPreviousDay => DateTime(year, month, day - 1);

  /// `true` si [other] tombe le même jour civil.
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

/// Nombre de jours civils entre deux dates locales, insensible aux changements d'heure.
int calendarDaysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Mois civils révolus de [from] à [to], heure ignorée ; négatif si [to] précède [from].
int completedMonthsBetween(DateTime from, DateTime to) {
  final months = (to.year - from.year) * 12 + to.month - from.month;
  return to.day < from.day ? months - 1 : months;
}

/// Premier jour civil où [completedMonthsBetween] depuis [from] atteint [months].
/// Le 31 août + 6 mois donne le 1er mars (février n'a pas de 31).
DateTime dateAfterCompletedMonths(DateTime from, int months) {
  final target = DateTime(from.year, from.month + months);
  final daysInTarget = DateTime(target.year, target.month + 1, 0).day;
  return from.day <= daysInTarget
      ? DateTime(target.year, target.month, from.day)
      : DateTime(target.year, target.month + 1);
}
