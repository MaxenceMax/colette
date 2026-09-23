import 'package:colette/core/dates/time_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  test('formatShortDate : « 22 sept. 2026 »', () {
    expect(formatShortDate(DateTime(2026, 9, 22)), '22 sept. 2026');
  });

  test('formatShortWeekday donne le jour abrégé et son numéro', () {
    expect(formatShortWeekday(DateTime(2026, 9, 23)), 'mer. 23');
  });
}
