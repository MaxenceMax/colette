import 'package:colette/core/dates/date_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dateOnly supprime l\'heure', () {
    expect(DateTime(2026, 9, 21, 14, 30).dateOnly, DateTime(2026, 9, 21));
  });

  test('isSameDay compare le jour civil', () {
    expect(
      DateTime(2026, 9, 21, 1).isSameDay(DateTime(2026, 9, 21, 23)),
      isTrue,
    );
    expect(
      DateTime(2026, 9, 21, 23).isSameDay(DateTime(2026, 9, 22, 0)),
      isFalse,
    );
  });

  test('startOfNextDay renvoie minuit du lendemain', () {
    expect(DateTime(2026, 9, 21, 14).startOfNextDay, DateTime(2026, 9, 22));
  });

  test('startOfNextDay franchit les fins de mois et d\'année', () {
    expect(DateTime(2026, 12, 31, 9).startOfNextDay, DateTime(2027, 1, 1));
    expect(DateTime(2028, 2, 28, 9).startOfNextDay, DateTime(2028, 2, 29));
  });

  test('calendarDaysBetween compte des jours civils, insensible au changement d\'heure (DST)', () {
    // Passage à l'heure d'été le 29 mars 2026 : `DateTime.difference` en
    // heure locale perdrait 1h et compterait 9 jours au lieu de 10.
    expect(
      calendarDaysBetween(DateTime(2026, 3, 20), DateTime(2026, 3, 30, 12)),
      10,
    );
    expect(
      calendarDaysBetween(DateTime(2026, 3, 20), DateTime(2026, 10, 26)),
      220,
    );
  });
}
