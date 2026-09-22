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
}
