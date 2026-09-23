import 'package:colette/l10n/generated/app_localizations.dart';

/// « 42 min », « 2 h », « 1 h 05 ». Une durée négative est bornée à zéro.
String formatDuration(Duration duration, S s) {
  final minutes = duration.isNegative ? 0 : duration.inMinutes;
  if (minutes < Duration.minutesPerHour) return s.durationMinutes(minutes);
  final hours = minutes ~/ Duration.minutesPerHour;
  final rest = minutes % Duration.minutesPerHour;
  if (rest == 0) return s.durationHours(hours);
  return s.durationHoursMinutes(hours, rest.toString().padLeft(2, '0'));
}
