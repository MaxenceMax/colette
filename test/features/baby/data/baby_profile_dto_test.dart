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
}
