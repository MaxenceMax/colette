import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';

/// Conversion `CareSettings` ↔ map Firestore.
abstract final class CareSettingsDto {
  static Map<String, dynamic> toMap(CareSettings settings) => {
    'adrigylPerDay': settings.adrigylPerDay,
    'eyeCarePerDay': settings.eyeCarePerDay,
    'noseCarePerDay': settings.noseCarePerDay,
    'umbilicalCarePerDay': settings.umbilicalCarePerDay,
    'bathEveryDays': settings.bathEveryDays,
    'feedsPerDay': settings.feedsPerDay,
    'dailyTargetMl': settings.dailyTargetMl?.clamp(
      CareSettings.minDailyTargetMl,
      CareSettings.maxDailyTargetMl,
    ),
  };

  static int _readInt(
    Map<String, dynamic> map,
    String key,
    int fallback, {
    required int min,
    required int max,
  }) {
    final raw = map[key];
    return (raw is num && raw.isFinite ? raw.toInt() : fallback).clamp(
      min,
      max,
    );
  }

  /// Entier optionnel borné ; absent ou non numérique → `null`.
  /// Arrondi au multiple de `step` le plus proche avant de borner.
  static int? _readOptionalInt(
    Map<String, dynamic> map,
    String key, {
    required int min,
    required int max,
    int step = 1,
  }) {
    final raw = map[key];
    if (raw is! num || !raw.isFinite) return null;
    final rounded = (raw.toInt() / step).round() * step;
    return rounded.clamp(min, max);
  }

  /// Documents antérieurs : seul le booléen `umbilicalCareEnabled` existe.
  static int _readUmbilicalCarePerDay(Map<String, dynamic> map) {
    final fallback = const CareSettings().umbilicalCarePerDay;
    if (map['umbilicalCarePerDay'] is num) {
      return _readInt(map, 'umbilicalCarePerDay', fallback, min: 0, max: 10);
    }
    return map['umbilicalCareEnabled'] == false ? 0 : fallback;
  }

  /// Borne chaque valeur à une plage sûre : un document modifié à la main ne doit jamais casser les calculs.
  static CareSettings fromMap(Map<String, dynamic> map) => CareSettings(
    adrigylPerDay: _readInt(map, 'adrigylPerDay', 1, min: 0, max: 10),
    eyeCarePerDay: _readInt(map, 'eyeCarePerDay', 1, min: 0, max: 10),
    noseCarePerDay: _readInt(map, 'noseCarePerDay', 1, min: 0, max: 10),
    umbilicalCarePerDay: _readUmbilicalCarePerDay(map),
    bathEveryDays: _readInt(map, 'bathEveryDays', 2, min: 1, max: 30),
    feedsPerDay: _readInt(map, 'feedsPerDay', 8, min: 1, max: 24),
    dailyTargetMl: _readOptionalInt(
      map,
      'dailyTargetMl',
      min: CareSettings.minDailyTargetMl,
      max: CareSettings.maxDailyTargetMl,
      step: CareSettings.dailyTargetStepMl,
    ),
  );
}

/// Conversion `BabyProfile` ↔ champ `baby` du document foyer.
abstract final class BabyProfileDto {
  static Map<String, dynamic> toMap(BabyProfile profile) => {
    'name': profile.name,
    'birthDate': Timestamp.fromDate(profile.birthDate),
    'cordFallenAt': switch (profile.cordFallenAt) {
      null => null,
      final date => Timestamp.fromDate(date),
    },
    'sex': profile.sex?.name,
    'careSettings': CareSettingsDto.toMap(profile.careSettings),
  };

  static BabyProfile fromMap(Map<String, dynamic> map) => BabyProfile(
    name: map['name'] as String? ?? '',
    birthDate: (map['birthDate'] as Timestamp).toDate(),
    cordFallenAt: (map['cordFallenAt'] as Timestamp?)?.toDate(),
    sex: BabySex.values.where((sex) => sex.name == map['sex']).firstOrNull,
    careSettings: CareSettingsDto.fromMap(
      (map['careSettings'] as Map<String, dynamic>?) ?? const {},
    ),
  );
}
