import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';

/// Entier borné ; absent, non numérique ou non fini → [fallback].
int _readBoundedInt(
  Map<String, dynamic> map,
  String key,
  int fallback, {
  required int min,
  required int max,
}) {
  final raw = map[key];
  return (raw is num && raw.isFinite ? raw.toInt() : fallback).clamp(min, max);
}

/// Conversion `CareFrequency` ↔ map Firestore `{timesPerDay, everyDays, enabled}`.
abstract final class CareFrequencyDto {
  static const maxTimesPerDay = 10;
  static const maxEveryDays = 30;

  static Map<String, dynamic> toMap(CareFrequency frequency) => {
    'timesPerDay': frequency.timesPerDay,
    'everyDays': frequency.everyDays,
    'enabled': frequency.enabled,
  };

  /// Bornes 1..10 et 1..30, `enabled` vrai par défaut ; si les deux entiers
  /// dépassent 1, `timesPerDay` est ramené à 1 (invariant de l'entité).
  static CareFrequency fromMap(Map<String, dynamic> map) {
    final everyDays = _readBoundedInt(
      map,
      'everyDays',
      1,
      min: 1,
      max: maxEveryDays,
    );
    final timesPerDay = everyDays > 1
        ? 1
        : _readBoundedInt(map, 'timesPerDay', 1, min: 1, max: maxTimesPerDay);
    final enabled = map['enabled'];
    return CareFrequency(
      timesPerDay: timesPerDay,
      everyDays: everyDays,
      enabled: enabled is bool ? enabled : true,
    );
  }

  /// Ancien entier « fois par jour » : `n > 0` → `n`/jour ; `0` → [fallback] désactivé.
  static CareFrequency fromLegacyPerDay(Object? raw, CareFrequency fallback) {
    if (raw is! num || !raw.isFinite) return fallback;
    final value = raw.toInt();
    if (value <= 0) return fallback.copyWith(enabled: false);
    return CareFrequency(timesPerDay: value.clamp(1, maxTimesPerDay));
  }
}

/// Conversion `CareSettings` ↔ map Firestore.
abstract final class CareSettingsDto {
  static Map<String, dynamic> toMap(CareSettings settings) => {
    'adrigyl': CareFrequencyDto.toMap(settings.adrigyl),
    'eyeCare': CareFrequencyDto.toMap(settings.eyeCare),
    'noseCare': CareFrequencyDto.toMap(settings.noseCare),
    'umbilicalCare': CareFrequencyDto.toMap(settings.umbilicalCare),
    'bath': CareFrequencyDto.toMap(settings.bath),
    'feedsPerDay': settings.feedsPerDay,
    'nightStartHour': settings.nightStartHour,
    'nightEndHour': settings.nightEndHour,
    'dailyTargetMl': settings.dailyTargetMl?.clamp(
      CareSettings.minDailyTargetMl,
      CareSettings.maxDailyTargetMl,
    ),
  };

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

  /// Map du soin si présente, sinon ancien entier `xPerDay`, sinon [fallback].
  static CareFrequency _readFrequency(
    Map<String, dynamic> map,
    String key, {
    required String legacyKey,
    required CareFrequency fallback,
  }) {
    if (map[key] case final Map<String, dynamic> nested) {
      return CareFrequencyDto.fromMap(nested);
    }
    return CareFrequencyDto.fromLegacyPerDay(map[legacyKey], fallback);
  }

  /// Documents antérieurs : entier `umbilicalCarePerDay`, ou booléen `umbilicalCareEnabled`.
  static CareFrequency _readUmbilicalCare(Map<String, dynamic> map) {
    final fallback = const CareSettings().umbilicalCare;
    if (map['umbilicalCare'] case final Map<String, dynamic> nested) {
      return CareFrequencyDto.fromMap(nested);
    }
    if (map['umbilicalCarePerDay'] is num) {
      return CareFrequencyDto.fromLegacyPerDay(
        map['umbilicalCarePerDay'],
        fallback,
      );
    }
    return map['umbilicalCareEnabled'] == false
        ? fallback.copyWith(enabled: false)
        : fallback;
  }

  /// Documents antérieurs : entier `bathEveryDays`.
  static CareFrequency _readBath(Map<String, dynamic> map) {
    final fallback = const CareSettings().bath;
    if (map['bath'] case final Map<String, dynamic> nested) {
      return CareFrequencyDto.fromMap(nested);
    }
    final raw = map['bathEveryDays'];
    if (raw is! num || !raw.isFinite) return fallback;
    return CareFrequency(
      everyDays: raw.toInt().clamp(1, CareFrequencyDto.maxEveryDays),
    );
  }

  /// Borne chaque valeur à une plage sûre : un document modifié à la main ne doit jamais casser les calculs.
  static CareSettings fromMap(Map<String, dynamic> map) {
    const defaults = CareSettings();
    return CareSettings(
      adrigyl: _readFrequency(
        map,
        'adrigyl',
        legacyKey: 'adrigylPerDay',
        fallback: defaults.adrigyl,
      ),
      eyeCare: _readFrequency(
        map,
        'eyeCare',
        legacyKey: 'eyeCarePerDay',
        fallback: defaults.eyeCare,
      ),
      noseCare: _readFrequency(
        map,
        'noseCare',
        legacyKey: 'noseCarePerDay',
        fallback: defaults.noseCare,
      ),
      umbilicalCare: _readUmbilicalCare(map),
      bath: _readBath(map),
      feedsPerDay: _readBoundedInt(map, 'feedsPerDay', 8, min: 1, max: 24),
      nightStartHour: _readBoundedInt(
        map,
        'nightStartHour',
        20,
        min: 0,
        max: 23,
      ),
      nightEndHour: _readBoundedInt(map, 'nightEndHour', 7, min: 0, max: 23),
      dailyTargetMl: _readOptionalInt(
        map,
        'dailyTargetMl',
        min: CareSettings.minDailyTargetMl,
        max: CareSettings.maxDailyTargetMl,
        step: CareSettings.dailyTargetStepMl,
      ),
    );
  }
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
