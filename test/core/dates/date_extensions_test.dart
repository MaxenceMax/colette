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

  group('completedMonthsBetween', () {
    test('compte les mois civils révolus', () {
      expect(
        completedMonthsBetween(DateTime(2026, 9, 15), DateTime(2027, 3, 14)),
        5,
      );
      expect(
        completedMonthsBetween(DateTime(2026, 9, 15), DateTime(2027, 3, 15)),
        6,
      );
    });

    test('ignore l\'heure', () {
      expect(
        completedMonthsBetween(
          DateTime(2026, 9, 15, 23),
          DateTime(2026, 10, 15, 1),
        ),
        1,
      );
    });

    test('fin de mois : le 31 août atteint 6 mois le 1er mars', () {
      expect(
        completedMonthsBetween(DateTime(2026, 8, 31), DateTime(2027, 2, 28)),
        5,
      );
      expect(
        completedMonthsBetween(DateTime(2026, 8, 31), DateTime(2027, 3, 1)),
        6,
      );
    });

    test('négatif si to précède from', () {
      expect(
        completedMonthsBetween(DateTime(2026, 9, 15), DateTime(2026, 8, 15)),
        -1,
      );
    });
  });

  group('dateAfterCompletedMonths', () {
    test('même jour du mois quand il existe', () {
      expect(
        dateAfterCompletedMonths(DateTime(2026, 9, 15, 10), 6),
        DateTime(2027, 3, 15),
      );
    });

    test('1er du mois suivant quand le jour n\'existe pas', () {
      expect(
        dateAfterCompletedMonths(DateTime(2026, 8, 31), 6),
        DateTime(2027, 3, 1),
      );
    });

    test('cohérent avec completedMonthsBetween', () {
      final birth = DateTime(2026, 8, 31);
      final date = dateAfterCompletedMonths(birth, 6);
      expect(completedMonthsBetween(birth, date), 6);
      expect(completedMonthsBetween(birth, date.startOfPreviousDay), 5);
    });
  });
}
