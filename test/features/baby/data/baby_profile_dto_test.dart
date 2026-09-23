import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/baby/data/dtos/baby_profile_dto.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _sexTests();

  test('CareSettingsDto.fromMap ignore une valeur non numérique', () {
    expect(
      CareSettingsDto.fromMap(const {'bathEveryDays': '5'}).bathEveryDays,
      2,
    );
  });

  test('CareSettingsDto.fromMap applique les défauts sur une map vide', () {
    expect(CareSettingsDto.fromMap(const {}), const CareSettings());
  });

  test('CareSettingsDto.fromMap borne les valeurs aberrantes', () {
    final settings = CareSettingsDto.fromMap(const {
      'feedsPerDay': 0,
      'bathEveryDays': 0,
      'adrigylPerDay': 99,
    });
    expect(settings.feedsPerDay, 1);
    expect(settings.bathEveryDays, 1);
    expect(settings.adrigylPerDay, 10);
  });

  test('CareSettingsDto.fromMap ignore une valeur non finie', () {
    expect(
      CareSettingsDto.fromMap(const {'feedsPerDay': double.infinity})
          .feedsPerDay,
      8,
    );
  });

  test('CareSettingsDto.fromMap lit umbilicalCarePerDay borné', () {
    expect(
      CareSettingsDto.fromMap(const {'umbilicalCarePerDay': 2})
          .umbilicalCarePerDay,
      2,
    );
    expect(
      CareSettingsDto.fromMap(const {'umbilicalCarePerDay': 42})
          .umbilicalCarePerDay,
      10,
    );
  });

  test(
    'CareSettingsDto.fromMap replie sur l\'ancien booléen umbilicalCareEnabled',
    () {
      expect(
        CareSettingsDto.fromMap(const {'umbilicalCareEnabled': false})
            .umbilicalCarePerDay,
        0,
      );
      expect(
        CareSettingsDto.fromMap(const {'umbilicalCareEnabled': true})
            .umbilicalCarePerDay,
        3,
      );
      expect(
        CareSettingsDto.fromMap(const {
          'umbilicalCarePerDay': 0,
          'umbilicalCareEnabled': true,
        }).umbilicalCarePerDay,
        0,
      );
    },
  );

  test(
    'CareSettingsDto.toMap écrit umbilicalCarePerDay et plus le booléen',
    () {
      final map = CareSettingsDto.toMap(
        const CareSettings(umbilicalCarePerDay: 2),
      );
      expect(map['umbilicalCarePerDay'], 2);
      expect(map.containsKey('umbilicalCareEnabled'), isFalse);
    },
  );

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
