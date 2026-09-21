/// Aides sur les jours civils (heure locale de l'appareil).
extension DateOnlyX on DateTime {
  /// Minuit du même jour.
  DateTime get dateOnly => DateTime(year, month, day);

  /// Minuit du lendemain.
  DateTime get startOfNextDay => DateTime(year, month, day + 1);

  /// `true` si [other] tombe le même jour civil.
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
