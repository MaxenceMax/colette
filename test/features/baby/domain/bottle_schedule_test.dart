import 'package:colette/features/baby/domain/entities/bottle_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Défauts : premier biberon 7 h, biberon du soir 23 h 30, toutes les 3 h.
  const schedule = BottleSchedule();

  group('nextAfter', () {
    DateTime next(int day, int hour, [int minute = 0]) =>
        schedule.nextAfter(DateTime(2026, 9, day, hour, minute));

    test('journée : dernier biberon + intervalle', () {
      expect(next(10, 10), DateTime(2026, 9, 10, 13));
    });

    test('journée : rabattu sur le biberon du soir', () {
      expect(next(10, 22), DateTime(2026, 9, 10, 23, 30));
      expect(next(10, 22, 45), DateTime(2026, 9, 10, 23, 30));
    });

    test('biberon du soir : le suivant est le premier du matin', () {
      expect(next(10, 23), DateTime(2026, 9, 11, 7));
      expect(next(10, 23, 10), DateTime(2026, 9, 11, 7));
      expect(next(10, 23, 30), DateTime(2026, 9, 11, 7));
    });

    test('nuit après minuit : premier du matin le jour même', () {
      expect(next(11, 0, 30), DateTime(2026, 9, 11, 7));
    });

    test('nuit : garde dernier + intervalle s\'il dépasse le matin', () {
      expect(next(11, 5), DateTime(2026, 9, 11, 8));
      expect(next(11, 6), DateTime(2026, 9, 11, 9));
    });

    test('dès 30 min avant le premier biberon, c\'est la journée', () {
      expect(next(11, 6, 30), DateTime(2026, 9, 11, 9, 30));
      expect(next(11, 6, 40), DateTime(2026, 9, 11, 9, 40));
    });

    test('réglages personnalisés', () {
      const custom = BottleSchedule(
        firstBottle: Duration(hours: 6, minutes: 30),
        lastBottle: Duration(hours: 22),
        interval: Duration(hours: 2, minutes: 45),
      );
      expect(
        custom.nextAfter(DateTime(2026, 9, 10, 18)),
        DateTime(2026, 9, 10, 20, 45),
      );
      expect(
        custom.nextAfter(DateTime(2026, 9, 10, 20, 45)),
        DateTime(2026, 9, 10, 22),
      );
      expect(
        custom.nextAfter(DateTime(2026, 9, 10, 22)),
        DateTime(2026, 9, 11, 6, 30),
      );
    });

    test('toujours strictement après le dernier biberon', () {
      for (var minutes = 0; minutes < 24 * 60; minutes += 5) {
        final last = DateTime(2026, 9, 10, 0, minutes);
        expect(schedule.nextAfter(last).isAfter(last), isTrue, reason: '$last');
      }
    });
  });

  test('windowAround : de 30 min avant à 30 min après', () {
    expect(schedule.windowAround(DateTime(2026, 9, 11, 7)), (
      DateTime(2026, 9, 11, 6, 30),
      DateTime(2026, 9, 11, 7, 30),
    ));
  });

  group('feedsPerDay', () {
    test('7 h → 23 h 30 toutes les 3 h : 7', () {
      expect(schedule.feedsPerDay, 7);
    });

    test('intervalle qui divise exactement la plage', () {
      const exact = BottleSchedule(
        firstBottle: Duration(hours: 6, minutes: 30),
        lastBottle: Duration(hours: 23, minutes: 30),
        interval: Duration(hours: 2, minutes: 50),
      );
      expect(exact.feedsPerDay, 7);
    });

    test('7 h → 22 h toutes les 5 h : 4', () {
      const sparse = BottleSchedule(
        lastBottle: Duration(hours: 22),
        interval: Duration(hours: 5),
      );
      expect(sparse.feedsPerDay, 4);
    });

    test('plage vide : au moins 1', () {
      const empty = BottleSchedule(
        firstBottle: Duration(hours: 10),
        lastBottle: Duration(hours: 8),
      );
      expect(empty.feedsPerDay, 1);
    });
  });
}
