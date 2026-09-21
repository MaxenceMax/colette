import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// « Aujourd'hui », « Hier », sinon « Mardi 15 septembre ».
String dayLabel(DateTime day, {required DateTime now, required S s}) {
  if (day.isSameDay(now)) return s.dayToday;
  if (day.isSameDay(now.subtract(const Duration(days: 1)))) {
    return s.dayYesterday;
  }
  final text = DateFormat('EEEE d MMMM', 'fr').format(day);
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
