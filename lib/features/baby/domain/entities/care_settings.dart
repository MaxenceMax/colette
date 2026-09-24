import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_settings.freezed.dart';

/// Fréquences des soins attendus, cible de lait ajustée et horaires de nuit.
@freezed
abstract class CareSettings with _$CareSettings {
  const CareSettings._();

  const factory CareSettings({
    @Default(CareFrequency()) CareFrequency adrigyl,
    @Default(CareFrequency()) CareFrequency eyeCare,
    @Default(CareFrequency()) CareFrequency noseCare,
    @Default(CareFrequency(timesPerDay: 3)) CareFrequency umbilicalCare,
    @Default(CareFrequency(everyDays: 2)) CareFrequency bath,
    @Default(8) int feedsPerDay,

    /// Heure (0-23) à partir de laquelle un endormissement est une nuit.
    @Default(20) int nightStartHour,

    /// Heure (0-23) à partir de laquelle un endormissement redevient une sieste.
    @Default(7) int nightEndHour,

    /// Cible journalière forcée en ml ; `null` = calcul OMS.
    int? dailyTargetMl,
  }) = _CareSettings;

  static const minDailyTargetMl = 100;
  static const maxDailyTargetMl = 1500;
  static const dailyTargetStepMl = 10;

  /// Fréquence d'un soin programmé ([CareType.isScheduled]).
  CareFrequency frequencyOf(CareType type) => switch (type) {
    CareType.adrigyl => adrigyl,
    CareType.eyeCare => eyeCare,
    CareType.noseCare => noseCare,
    CareType.umbilicalCare => umbilicalCare,
    CareType.bath => bath,
    CareType.pee || CareType.poop || CareType.diaperChange =>
      throw ArgumentError.value(type, 'type', 'sans fréquence attendue'),
  };

  /// Copie avec la fréquence d'un soin programmé remplacée.
  CareSettings withFrequency(CareType type, CareFrequency frequency) =>
      switch (type) {
        CareType.adrigyl => copyWith(adrigyl: frequency),
        CareType.eyeCare => copyWith(eyeCare: frequency),
        CareType.noseCare => copyWith(noseCare: frequency),
        CareType.umbilicalCare => copyWith(umbilicalCare: frequency),
        CareType.bath => copyWith(bath: frequency),
        CareType.pee || CareType.poop || CareType.diaperChange =>
          throw ArgumentError.value(type, 'type', 'sans fréquence attendue'),
      };
}
