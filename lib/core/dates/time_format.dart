import 'package:intl/intl.dart';

/// « 14h32 ».
String formatHourMinute(DateTime time) =>
    DateFormat("HH'h'mm", 'fr').format(time);

/// « lun. 21 sept., 14h32 ».
String formatDayAndTime(DateTime time) =>
    DateFormat("EEE d MMM, HH'h'mm", 'fr').format(time);
