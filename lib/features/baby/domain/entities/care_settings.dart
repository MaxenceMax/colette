import 'package:colette/features/baby/domain/entities/bottle_schedule.dart';
import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_settings.freezed.dart';

/// Fréquences des soins attendus, cible de lait, horaires des biberons et de nuit.
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

    /// Heure du premier biberon, en minutes depuis minuit.
    @Default(420) int firstBottleMinutes,

    /// Heure du biberon du soir, en minutes depuis minuit.
    @Default(1410) int lastBottleMinutes,

    /// Intervalle entre deux biberons, en minutes.
    @Default(180) int bottleIntervalMinutes,
  }) = _CareSettings;

  static const minDailyTargetMl = 100;
  static const maxDailyTargetMl = 1500;
  static const dailyTargetStepMl = 10;
  static const bottleTimeStepMinutes = 15;
  static const minFirstBottleMinutes = 4 * 60;
  static const maxFirstBottleMinutes = 10 * 60;
  static const minLastBottleMinutes = 20 * 60;
  static const maxLastBottleMinutes = 23 * 60 + 45;
  static const minBottleIntervalMinutes = 90;
  static const maxBottleIntervalMinutes = 5 * 60;

  /// Rythme des biberons tiré des trois réglages.
  BottleSchedule get bottleSchedule => BottleSchedule(
    firstBottle: Duration(minutes: firstBottleMinutes),
    lastBottle: Duration(minutes: lastBottleMinutes),
    interval: Duration(minutes: bottleIntervalMinutes),
  );

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
