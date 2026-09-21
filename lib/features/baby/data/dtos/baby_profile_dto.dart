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

  static CareSettings fromMap(Map<String, dynamic> map) => CareSettings(
    adrigylPerDay: (map['adrigylPerDay'] as num?)?.toInt() ?? 1,
    eyeCarePerDay: (map['eyeCarePerDay'] as num?)?.toInt() ?? 1,
    noseCarePerDay: (map['noseCarePerDay'] as num?)?.toInt() ?? 1,
    umbilicalCareEnabled: map['umbilicalCareEnabled'] as bool? ?? true,
    bathEveryDays: (map['bathEveryDays'] as num?)?.toInt() ?? 2,
    feedsPerDay: (map['feedsPerDay'] as num?)?.toInt() ?? 8,
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
