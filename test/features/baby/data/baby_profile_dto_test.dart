import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/baby/data/dtos/baby_profile_dto.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _sexTests();
  group('CareFrequency', () {
    test('toMap écrit une map par soin et plus aucun champ plat', () {
      final map = CareSettingsDto.toMap(const CareSettings());
      expect(map['adrigyl'], {
        'timesPerDay': 1,
        'everyDays': 1,
        'enabled': true,
      });
      expect(map['umbilicalCare'], {
        'timesPerDay': 3,
        'everyDays': 1,
        'enabled': true,
      });
      expect(map['bath'], {'timesPerDay': 1, 'everyDays': 2, 'enabled': true});
      for (final legacy in [
        'adrigylPerDay',
        'eyeCarePerDay',
        'noseCarePerDay',
        'umbilicalCarePerDay',
        'umbilicalCareEnabled',
        'bathEveryDays',
      ]) {
        expect(map.containsKey(legacy), isFalse, reason: legacy);
      }
    });

    test('aller-retour', () {
      const settings = CareSettings(
        adrigyl: CareFrequency(everyDays: 3, enabled: false),
        bath: CareFrequency(timesPerDay: 2),
      );
      expect(
        CareSettingsDto.fromMap(CareSettingsDto.toMap(settings)),
        settings,
      );
    });

    test('map vide : défauts', () {
      expect(CareSettingsDto.fromMap(const {}), const CareSettings());
    });

    test('map de soin : bornes 1..10 et 1..30, enabled vrai par défaut', () {
      final settings = CareSettingsDto.fromMap(const {
        'adrigyl': {'timesPerDay': 99},
        'bath': {'everyDays': 60, 'enabled': 'oui'},
        'eyeCare': {'timesPerDay': 0, 'everyDays': -1},
      });
      expect(settings.adrigyl, const CareFrequency(timesPerDay: 10));
      expect(settings.bath, const CareFrequency(everyDays: 30));
      expect(settings.eyeCare, const CareFrequency());
    });

    test('map de soin : deux entiers > 1 → timesPerDay ramené à 1', () {
      expect(
        CareSettingsDto.fromMap(const {
          'noseCare': {'timesPerDay': 3, 'everyDays': 2},
        }).noseCare,
        const CareFrequency(everyDays: 2),
      );
    });

    test('ancien entier xPerDay : n > 0 → n/jour, 0 → désactivé avec la fréquence par défaut', () {
      final settings = CareSettingsDto.fromMap(const {
        'adrigylPerDay': 2,
        'eyeCarePerDay': 0,
        'noseCarePerDay': 99,
        'umbilicalCarePerDay': 0,
      });
      expect(settings.adrigyl, const CareFrequency(timesPerDay: 2));
      expect(settings.eyeCare, const CareFrequency(enabled: false));
      expect(settings.noseCare, const CareFrequency(timesPerDay: 10));
      expect(
        settings.umbilicalCare,
        const CareFrequency(timesPerDay: 3, enabled: false),
      );
    });

    test('ancien entier non numérique ou non fini : défaut', () {
      expect(
        CareSettingsDto.fromMap(const {'bathEveryDays': '5'}).bath,
        const CareFrequency(everyDays: 2),
      );
      expect(
        CareSettingsDto.fromMap(const {'adrigylPerDay': double.nan}).adrigyl,
        const CareFrequency(),
      );
    });

    test('ancien bathEveryDays : tous les n jours, borné 1..30', () {
      expect(
        CareSettingsDto.fromMap(const {'bathEveryDays': 3}).bath,
        const CareFrequency(everyDays: 3),
      );
      expect(
        CareSettingsDto.fromMap(const {'bathEveryDays': 0}).bath,
        const CareFrequency(),
      );
      expect(
        CareSettingsDto.fromMap(const {'bathEveryDays': 60}).bath,
        const CareFrequency(everyDays: 30),
      );
    });

    test('nombril : repli sur l\'ancien booléen umbilicalCareEnabled', () {
      expect(
        CareSettingsDto.fromMap(const {'umbilicalCareEnabled': false})
            .umbilicalCare,
        const CareFrequency(timesPerDay: 3, enabled: false),
      );
      expect(
        CareSettingsDto.fromMap(const {'umbilicalCareEnabled': true})
            .umbilicalCare,
        const CareFrequency(timesPerDay: 3),
      );
      expect(
        CareSettingsDto.fromMap(const {
          'umbilicalCarePerDay': 0,
          'umbilicalCareEnabled': true,
        }).umbilicalCare,
        const CareFrequency(timesPerDay: 3, enabled: false),
      );
      expect(
        CareSettingsDto.fromMap(const {
          'umbilicalCarePerDay': double.nan,
          'umbilicalCareEnabled': false,
        }).umbilicalCare,
        const CareFrequency(timesPerDay: 3, enabled: false),
      );
    });

    test('la map de soin prime sur l\'ancien entier', () {
      expect(
        CareSettingsDto.fromMap(const {
          'adrigyl': {'everyDays': 2},
          'adrigylPerDay': 0,
        }).adrigyl,
        const CareFrequency(everyDays: 2),
      );
    });
  });

  test('CareSettingsDto.fromMap borne feedsPerDay', () {
    expect(CareSettingsDto.fromMap(const {'feedsPerDay': 0}).feedsPerDay, 1);
    expect(
      CareSettingsDto.fromMap(const {'feedsPerDay': double.infinity})
          .feedsPerDay,
      8,
    );
  });

  group('dailyTargetMl', () {
    test('aller-retour avec une cible ajustée', () {
      const settings = CareSettings(dailyTargetMl: 600);
      final map = CareSettingsDto.toMap(settings);
      expect(map['dailyTargetMl'], 600);
      expect(CareSettingsDto.fromMap(map), settings);
    });

    test('absent ou invalide → null', () {
      expect(CareSettingsDto.fromMap(const {}).dailyTargetMl, isNull);
      expect(
        CareSettingsDto.fromMap(const {'dailyTargetMl': null}).dailyTargetMl,
        isNull,
      );
      expect(
        CareSettingsDto.fromMap(const {'dailyTargetMl': 'abc'}).dailyTargetMl,
        isNull,
      );
    });

    test('borné entre 100 et 1500', () {
      expect(
        CareSettingsDto.fromMap(const {'dailyTargetMl': 50}).dailyTargetMl,
        100,
      );
      expect(
        CareSettingsDto.fromMap(const {'dailyTargetMl': 9999}).dailyTargetMl,
        1500,
      );
    });

    test('toMap écrit null sans cible ajustée', () {
      final map = CareSettingsDto.toMap(const CareSettings());
      expect(map.containsKey('dailyTargetMl'), isTrue);
      expect(map['dailyTargetMl'], isNull);
    });

    test('NaN → null', () {
      expect(
        CareSettingsDto.fromMap(const {'dailyTargetMl': double.nan})
            .dailyTargetMl,
        isNull,
      );
    });

    test('arrondi au pas de 10', () {
      expect(
        CareSettingsDto.fromMap(const {'dailyTargetMl': 617}).dailyTargetMl,
        620,
      );
      expect(
        CareSettingsDto.fromMap(const {'dailyTargetMl': 614}).dailyTargetMl,
        610,
      );
    });

    test('toMap borne la valeur', () {
      expect(
        CareSettingsDto.toMap(
          const CareSettings(dailyTargetMl: 9999),
        )['dailyTargetMl'],
        1500,
      );
    });
  });

  group('horaires de nuit', () {
    test('valeurs par défaut 20 h et 7 h sans champ', () {
      final settings = CareSettingsDto.fromMap(const {});
      expect(settings.nightStartHour, 20);
      expect(settings.nightEndHour, 7);
    });

    test('aller-retour et bornes 0 à 23', () {
      const settings = CareSettings(nightStartHour: 21, nightEndHour: 6);
      expect(
        CareSettingsDto.fromMap(CareSettingsDto.toMap(settings)),
        settings,
      );
      final clamped = CareSettingsDto.fromMap(const {
        'nightStartHour': 30,
        'nightEndHour': -2,
      });
      expect(clamped.nightStartHour, 23);
      expect(clamped.nightEndHour, 0);
    });
  });
}

void _sexTests() {
  group('BabyProfileDto sexe', () {
    final base = {
      'name': 'Colette',
      'birthDate': Timestamp.fromDate(DateTime(2026, 9, 1)),
    };

    test('aller-retour fille et garçon', () {
      for (final sex in BabySex.values) {
        final profile = BabyProfile(
          name: 'Colette',
          birthDate: DateTime(2026, 9, 1),
          sex: sex,
        );
        expect(BabyProfileDto.toMap(profile)['sex'], sex.name);
        expect(BabyProfileDto.fromMap(BabyProfileDto.toMap(profile)).sex, sex);
      }
    });

    test('absent ou inconnu : non renseigné', () {
      expect(BabyProfileDto.fromMap(base).sex, isNull);
      expect(BabyProfileDto.fromMap({...base, 'sex': 'autre'}).sex, isNull);
      expect(BabyProfileDto.fromMap({...base, 'sex': 1}).sex, isNull);
    });

    test('non renseigné : écrit null', () {
      final profile = BabyProfile(name: 'C', birthDate: DateTime(2026, 9, 1));
      expect(BabyProfileDto.toMap(profile)['sex'], isNull);
    });
  });
}
