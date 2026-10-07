import 'package:colette/features/baby/domain/entities/bottle_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Défaut : 07h00, 10h00, 13h00, 16h00, 19h00, 22h00, 23h30.
  const schedule = BottleSchedule();
  DateTime at(int day, int hour, [int minute = 0]) =>
      DateTime(2026, 9, day, hour, minute);

  test('défaut : 7 horaires, de 7 h à 23 h 30', () {
    expect(schedule.feedsPerDay, 7);
    expect(schedule.times.first, const Duration(hours: 7));
    expect(schedule.times.last, const Duration(hours: 23, minutes: 30));
  });

  group('slotOf', () {
    test('horaire exact', () {
      expect(schedule.slotOf(at(10, 10)), at(10, 10));
    });

    test(
      'avant le milieu : horaire précédent ; au milieu et après : suivant',
      () {
        expect(schedule.slotOf(at(10, 11, 29)), at(10, 10));
        expect(schedule.slotOf(at(10, 11, 30)), at(10, 13));
        expect(schedule.slotOf(at(10, 12, 45)), at(10, 13));
      },
    );

    test('nuit : 23 h 30 jusqu\'au milieu (3 h 15), puis 7 h', () {
      expect(schedule.slotOf(at(11, 3)), at(10, 23, 30));
      expect(schedule.slotOf(at(11, 3, 15)), at(11, 7));
      expect(schedule.slotOf(at(10, 23, 50)), at(10, 23, 30));
    });

    test('tôt le matin : 6 h 30 compte pour 7 h', () {
      expect(schedule.slotOf(at(10, 6, 30)), at(10, 7));
    });
  });

  group('nextAfter', () {
    test('donné à l\'heure : horaire suivant', () {
      expect(schedule.nextAfter(at(10, 10)), at(10, 13));
    });

    test('donné en retard : la grille ne bouge pas', () {
      expect(schedule.nextAfter(at(10, 10, 45)), at(10, 13));
    });

    test('donné plus près de l\'horaire suivant : compte pour lui', () {
      expect(schedule.nextAfter(at(10, 12, 45)), at(10, 16));
    });

    test('biberon du soir ou de nuit : premier du lendemain', () {
      expect(schedule.nextAfter(at(10, 23, 30)), at(11, 7));
      expect(schedule.nextAfter(at(11, 2)), at(11, 7));
    });

    test('fin de mois', () {
      expect(
        schedule.nextAfter(DateTime(2026, 9, 30, 23, 30)),
        DateTime(2026, 10, 1, 7),
      );
    });
  });

  group('nextDue', () {
    test('horaire sauté : reste dû jusqu\'au milieu, puis le suivant', () {
      // Dernier biberon 7 h → 10 h dû ; milieu 10 h–13 h = 11 h 30.
      expect(schedule.nextDue(at(10, 7), at(10, 11, 29)), at(10, 10));
      expect(schedule.nextDue(at(10, 7), at(10, 11, 30)), at(10, 13));
      expect(schedule.nextDue(at(10, 7), at(10, 15)), at(10, 16));
    });

    test('nuit : aucun retard après le biberon du soir', () {
      expect(schedule.nextDue(at(10, 23, 30), at(11, 3)), at(11, 7));
    });

    test(
      'dernier biberon très ancien : horaire le plus proche de maintenant',
      () {
        expect(schedule.nextDue(at(8, 10), at(10, 14)), at(10, 13));
      },
    );
  });

  group('morningAfter', () {
    test('premier horaire strictement après', () {
      expect(schedule.morningAfter(at(10, 6)), at(10, 7));
      expect(schedule.morningAfter(at(10, 7)), at(11, 7));
      expect(schedule.morningAfter(at(10, 23, 30)), at(11, 7));
    });
  });

  group('grille personnalisée', () {
    const five = BottleSchedule(
      times: [
        Duration(hours: 7),
        Duration(hours: 10, minutes: 30),
        Duration(hours: 14),
        Duration(hours: 17, minutes: 30),
        Duration(hours: 21),
      ],
    );

    test('exemples de la spec', () {
      expect(five.feedsPerDay, 5);
      expect(five.nextAfter(at(10, 11, 15)), at(10, 14));
      expect(five.nextAfter(at(10, 12, 45)), at(10, 17, 30));
      expect(five.nextAfter(at(10, 12, 14)), at(10, 14));
    });
  });

  group('fromLegacy', () {
    BottleSchedule legacy(int first, int last, int interval) =>
        BottleSchedule.fromLegacy(
          first: Duration(minutes: first),
          last: Duration(minutes: last),
          interval: Duration(minutes: interval),
        );

    test('réglages par défaut : la grille par défaut', () {
      expect(legacy(420, 1410, 180), const BottleSchedule());
    });

    test('soir à au moins un demi-intervalle : ajouté', () {
      // 7 h, 12 h, 17 h, 22 h : écart 22 h – 17 h = 5 h ≥ 2 h 30.
      expect(legacy(420, 1320, 300).times, const [
        Duration(hours: 7),
        Duration(hours: 12),
        Duration(hours: 17),
        Duration(hours: 22),
      ]);
    });

    test('soir trop près du dernier créneau : il le remplace', () {
      // 7 h, 10 h 15, 13 h 30, 16 h 45, 20 h, 23 h 15 → 23 h 15 remplacé par 23 h 30.
      expect(legacy(420, 1410, 195).times, const [
        Duration(hours: 7),
        Duration(hours: 10, minutes: 15),
        Duration(hours: 13, minutes: 30),
        Duration(hours: 16, minutes: 45),
        Duration(hours: 20),
        Duration(hours: 23, minutes: 30),
      ]);
    });
  });
}
