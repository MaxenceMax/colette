import 'package:colette/features/baby/domain/entities/bottle_schedule.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defaults = CareSettings();
  const five = CareSettings(bottleTimesMinutes: [420, 630, 840, 1050, 1260]);

  test('défaut : la grille par défaut', () {
    expect(defaults.bottleTimesMinutes, [420, 600, 780, 960, 1140, 1320, 1410]);
    expect(defaults.bottleSchedule, const BottleSchedule());
  });

  group('bottleTimesAreValid', () {
    test('grille triée, écarts ≥ 30 min, nuit comprise', () {
      expect(CareSettings.bottleTimesAreValid([420, 600, 1410]), isTrue);
      expect(CareSettings.bottleTimesAreValid([0, 30, 1410]), isTrue);
    });

    test('refuse vide, non trié, hors 0–1439, trop proche', () {
      expect(CareSettings.bottleTimesAreValid([]), isFalse);
      expect(CareSettings.bottleTimesAreValid([600, 420]), isFalse);
      expect(CareSettings.bottleTimesAreValid([420, 1440]), isFalse);
      expect(CareSettings.bottleTimesAreValid([420, 445]), isFalse);
      // 23 h 50 → 0 h 10 le lendemain : 20 min.
      expect(CareSettings.bottleTimesAreValid([10, 600, 1430]), isFalse);
    });
  });

  group('withBottleCount', () {
    test('+1 : milieu du plus grand écart de journée, le premier en cas d\'égalité', () {
      expect(defaults.withBottleCount(8).bottleTimesMinutes, [
        420,
        510,
        600,
        780,
        960,
        1140,
        1320,
        1410,
      ]);
    });

    test('+1 : l\'écart de nuit n\'est jamais choisi', () {
      expect(five.withBottleCount(6).bottleTimesMinutes, [
        420,
        525,
        630,
        840,
        1050,
        1260,
      ]);
    });

    test('milieu arrondi au pas de 5 min inférieur', () {
      const odd = CareSettings(bottleTimesMinutes: [420, 485, 1200]);
      // Plus grand écart 485 → 1200 (715 min) : 485 + 355 = 840.
      expect(odd.withBottleCount(4).bottleTimesMinutes, [420, 485, 840, 1200]);
    });

    test('−1 : retire le dernier', () {
      expect(five.withBottleCount(4).bottleTimesMinutes, [420, 630, 840, 1050]);
    });

    test('même nombre : inchangé', () {
      expect(five.withBottleCount(5), five);
    });
  });

  group('canAddBottle', () {
    test('vrai avec un écart de journée ≥ 60 min et moins de 12 biberons', () {
      expect(defaults.canAddBottle, isTrue);
    });

    test('faux à 12 biberons', () {
      final twelve = defaults.withBottleCount(12);
      expect(twelve.bottleTimesMinutes, hasLength(12));
      expect(twelve.canAddBottle, isFalse);
    });

    test('faux si aucun écart de journée n\'atteint 60 min', () {
      const tight = CareSettings(bottleTimesMinutes: [600, 655, 710]);
      expect(tight.canAddBottle, isFalse);
    });
  });

  group('withBottleTime', () {
    test('remplace et retrie', () {
      expect(five.withBottleTime(0, 1380)!.bottleTimesMinutes, [
        630,
        840,
        1050,
        1260,
        1380,
      ]);
    });

    test('refuse un horaire à moins de 30 min d\'un autre', () {
      expect(five.withBottleTime(0, 610), isNull);
      expect(five.withBottleTime(4, 400), isNull);
    });

    test('accepte l\'horaire inchangé', () {
      expect(five.withBottleTime(2, 840), five);
    });
  });
}
