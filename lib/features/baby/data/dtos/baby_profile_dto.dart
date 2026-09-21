import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';

/// Conversion `CareSettings` ↔ map Firestore.
abstract final class CareSettingsDto {
  static Map<String, dynamic> toMap(CareSettings settings) => {
    'adrigylPerDay': settings.adrigylPerDay,
    'eyeCarePerDay': settings.eyeCarePerDay,
    'noseCarePerDay': settings.noseCarePerDay,
    'umbilicalCareEnabled': settings.umbilicalCareEnabled,
    'bathEveryDays': settings.bathEveryDays,
    'feedsPerDay': settings.feedsPerDay,
  };

  static int _readInt(
    Map<String, dynamic> map,
    String key,
    int fallback, {
    required int min,
    required int max,
  }) => ((map[key] as num?)?.toInt() ?? fallback).clamp(min, max);

  /// Borne chaque valeur à une plage sûre : un document modifié à la main ne doit jamais casser les calculs.
  static CareSettings fromMap(Map<String, dynamic> map) => CareSettings(
    adrigylPerDay: _readInt(map, 'adrigylPerDay', 1, min: 0, max: 10),
    eyeCarePerDay: _readInt(map, 'eyeCarePerDay', 1, min: 0, max: 10),
    noseCarePerDay: _readInt(map, 'noseCarePerDay', 1, min: 0, max: 10),
    umbilicalCareEnabled: map['umbilicalCareEnabled'] as bool? ?? true,
    bathEveryDays: _readInt(map, 'bathEveryDays', 2, min: 1, max: 30),
    feedsPerDay: _readInt(map, 'feedsPerDay', 8, min: 1, max: 24),
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
    'careSettings': CareSettingsDto.toMap(profile.careSettings),
  };

  static BabyProfile fromMap(Map<String, dynamic> map) => BabyProfile(
    name: map['name'] as String? ?? '',
    birthDate: (map['birthDate'] as Timestamp).toDate(),
    cordFallenAt: (map['cordFallenAt'] as Timestamp?)?.toDate(),
    careSettings: CareSettingsDto.fromMap(
      (map['careSettings'] as Map<String, dynamic>?) ?? const {},
    ),
  );
}
