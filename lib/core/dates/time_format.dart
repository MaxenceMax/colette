import 'package:intl/intl.dart';

/// « 14h32 ».
String formatHourMinute(DateTime time) =>
    DateFormat("HH'h'mm", 'fr').format(time);

/// « lun. 21 sept., 14h32 ».
String formatDayAndTime(DateTime time) =>
    DateFormat("EEE d MMM, HH'h'mm", 'fr').format(time);

/// « Lundi 21 septembre ».
String formatLongDate(DateTime day) {
  final text = DateFormat('EEEE d MMMM', 'fr').format(day);
  return '${text[0].toUpperCase()}${text.substring(1)}';
}

/// « 22 sept. 2026 ».
String formatShortDate(DateTime day) =>
    DateFormat('d MMM yyyy', 'fr').format(day);

/// « mer. 23 ».
String formatShortWeekday(DateTime day) =>
    DateFormat('EEE d', 'fr').format(day);

/// « 14 ».
String formatDayOfMonth(DateTime day) => DateFormat('d', 'fr').format(day);

/// « oct. ».
String formatShortMonth(DateTime day) => DateFormat('MMM', 'fr').format(day);

/// « 5 nov. ».
String formatDayMonth(DateTime day) => DateFormat('d MMM', 'fr').format(day);

/// « 29:05 ».
String formatCountdown(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
