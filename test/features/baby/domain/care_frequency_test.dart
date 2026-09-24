import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const daily = CareFrequency();
  final now = DateTime(2026, 9, 21, 14);

  group('previous (bouton −)', () {
    test('3/jour → 2/jour', () {
      expect(
        const CareFrequency(timesPerDay: 3).previous(),
        const CareFrequency(timesPerDay: 2),
      );
    });

    test('1/jour → tous les 2 jours', () {
      expect(daily.previous(), const CareFrequency(everyDays: 2));
    });

    test('tous les 2 jours → tous les 3 jours', () {
      expect(
        const CareFrequency(everyDays: 2).previous(),
        const CareFrequency(everyDays: 3),
      );
    });

    test('tous les 7 jours : butée', () {
      expect(const CareFrequency(everyDays: 7).previous(), isNull);
    });

    test('conserve enabled', () {
      expect(
        const CareFrequency(enabled: false).previous(),
        const CareFrequency(everyDays: 2, enabled: false),
      );
    });
  });

  group('next (bouton +)', () {
    test('tous les 3 jours → tous les 2 jours', () {
      expect(
        const CareFrequency(everyDays: 3).next(4),
        const CareFrequency(everyDays: 2),
      );
    });

    test('tous les 2 jours → 1/jour', () {
      expect(const CareFrequency(everyDays: 2).next(4), daily);
    });

    test('1/jour → 2/jour', () {
      expect(daily.next(4), const CareFrequency(timesPerDay: 2));
    });

    test('butée à maxTimesPerDay', () {
      expect(const CareFrequency(timesPerDay: 3).next(3), isNull);
    });
  });

  group('isExpected', () {
    test('désactivé : jamais attendu', () {
      expect(
        const CareFrequency(enabled: false)
            .isExpected(lastDoneAt: null, now: now),
        isFalse,
      );
    });

    test('1/jour : toujours attendu, même fait aujourd\'hui', () {
      expect(daily.isExpected(lastDoneAt: null, now: now), isTrue);
      expect(
        daily.isExpected(lastDoneAt: DateTime(2026, 9, 21, 8), now: now),
        isTrue,
      );
    });

    test('tous les 2 jours : attendu sans historique', () {
      expect(
        const CareFrequency(everyDays: 2)
            .isExpected(lastDoneAt: null, now: now),
        isTrue,
      );
    });

    test('tous les 2 jours, fait hier : pas attendu', () {
      expect(
        const CareFrequency(everyDays: 2)
            .isExpected(lastDoneAt: DateTime(2026, 9, 20, 18), now: now),
        isFalse,
      );
    });

    test('tous les 2 jours, fait avant-hier : attendu', () {
      expect(
        const CareFrequency(everyDays: 2)
            .isExpected(lastDoneAt: DateTime(2026, 9, 19, 18), now: now),
        isTrue,
      );
    });

    test('tous les 7 jours : pas attendu après 6 jours, attendu après 7', () {
      const weekly = CareFrequency(everyDays: 7);
      expect(
        weekly.isExpected(lastDoneAt: DateTime(2026, 9, 15, 18), now: now),
        isFalse,
      );
      expect(
        weekly.isExpected(lastDoneAt: DateTime(2026, 9, 14, 18), now: now),
        isTrue,
      );
    });

    test('DST : deux jours civils malgré le changement d\'heure', () {
      // Passage à l'heure d'été le 29 mars 2026 entre les deux instants.
      expect(
        const CareFrequency(everyDays: 2).isExpected(
          lastDoneAt: DateTime(2026, 3, 28, 20),
          now: DateTime(2026, 3, 30, 8),
        ),
        isTrue,
      );
    });
  });
}
