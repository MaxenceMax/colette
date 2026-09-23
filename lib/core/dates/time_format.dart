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
