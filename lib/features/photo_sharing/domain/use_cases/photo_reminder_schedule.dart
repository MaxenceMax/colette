import 'dart:math';

import 'package:colette/core/dates/date_extensions.dart';

/// Première heure possible du rappel photo.
const photoReminderStartHour = 8;

/// Heure de fin (exclue) du rappel photo.
const photoReminderEndHour = 21;

/// Nombre de jours programmés d'avance.
const photoReminderDays = 14;

/// Dates des rappels photo des [photoReminderDays] prochains jours, à une
/// minute tirée dans `[8:00, 21:00[`.
///
/// Le tirage d'un jour ne dépend que du jour (graine `aaaammjj`) : replanifier
/// redonne la même heure. Le jour courant est exclu si [lastSentAt] tombe
/// aujourd'hui ; les dates déjà passées sont exclues.
List<DateTime> planPhotoReminders({
  required DateTime now,
  required DateTime? lastSentAt,
  Random Function(int seed) randomForDay = Random.new,
}) {
  const window = (photoReminderEndHour - photoReminderStartHour) * 60;
  final sentToday = lastSentAt != null && lastSentAt.isSameDay(now);
  final dates = <DateTime>[];
  for (var offset = 0; offset < photoReminderDays; offset++) {
    if (offset == 0 && sentToday) continue;
    final day = DateTime(now.year, now.month, now.day + offset);
    final seed = day.year * 10000 + day.month * 100 + day.day;
    final minute = randomForDay(seed).nextInt(window);
    final at = DateTime(
      day.year,
      day.month,
      day.day,
      photoReminderStartHour,
      minute,
    );
    if (at.isAfter(now)) dates.add(at);
  }
  return dates;
}
