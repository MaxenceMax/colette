import 'package:colette/features/baby/data/dtos/baby_profile_dto.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
  });
}
