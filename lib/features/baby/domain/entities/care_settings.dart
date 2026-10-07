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

    /// Heure (0-23) à partir de laquelle un endormissement est une nuit.
    @Default(20) int nightStartHour,

    /// Heure (0-23) à partir de laquelle un endormissement redevient une sieste.
    @Default(7) int nightEndHour,

    /// Cible journalière forcée en ml ; `null` = calcul OMS.
    int? dailyTargetMl,

    /// Horaires des biberons, en minutes depuis minuit, triés.
    @Default([420, 600, 780, 960, 1140, 1320, 1410])
    List<int> bottleTimesMinutes,
  }) = _CareSettings;

  static const minDailyTargetMl = 100;
  static const maxDailyTargetMl = 1500;
  static const dailyTargetStepMl = 10;
  static const minBottlesPerDay = 3;
  static const maxBottlesPerDay = 12;
  static const bottleTimePickerStepMinutes = 5;
  static const minBottleGapMinutes = 30;
  static const _minutesPerDay = 24 * 60;

  /// Grille des biberons tirée des horaires réglés.
  BottleSchedule get bottleSchedule => BottleSchedule(
    times: [for (final m in bottleTimesMinutes) Duration(minutes: m)],
  );

  /// Grille non vide, triée, dans 0–1439, écarts d'au moins 30 min, y
  /// compris du dernier horaire au premier du lendemain.
  static bool bottleTimesAreValid(List<int> times) {
    if (times.isEmpty) return false;
    if (times.any((m) => m < 0 || m >= _minutesPerDay)) return false;
    for (var i = 1; i < times.length; i++) {
      if (times[i] - times[i - 1] < minBottleGapMinutes) return false;
    }
    return times.first + _minutesPerDay - times.last >= minBottleGapMinutes;
  }

  /// Milieu du plus grand écart entre deux horaires consécutifs de la
  /// journée, nuit exclue ; la moitié de l'écart est arrondie au pas de 5 min
  /// inférieur (pas l'horaire absolu). `null` si aucun écart n'atteint deux
  /// fois l'écart minimum.
  int? get _bottleInsertion {
    int? best;
    var bestGap = 2 * minBottleGapMinutes - 1;
    for (var i = 1; i < bottleTimesMinutes.length; i++) {
      final gap = bottleTimesMinutes[i] - bottleTimesMinutes[i - 1];
      if (gap > bestGap) {
        bestGap = gap;
        final half = gap ~/ 2;
        best =
            bottleTimesMinutes[i - 1] +
            half -
            half % bottleTimePickerStepMinutes;
      }
    }
    return best;
  }

  /// Un biberon de plus est-il possible ?
  bool get canAddBottle =>
      bottleTimesMinutes.length < maxBottlesPerDay && _bottleInsertion != null;

  /// Copie avec [count] biberons : ajoute au milieu du plus grand écart de
  /// journée (tant que [canAddBottle]), ou retire les derniers.
  CareSettings withBottleCount(int count) {
    var settings = this;
    while (settings.bottleTimesMinutes.length < count &&
        settings.canAddBottle) {
      final inserted = settings._bottleInsertion!;
      settings = settings.copyWith(
        bottleTimesMinutes: [...settings.bottleTimesMinutes, inserted]..sort(),
      );
    }
    if (settings.bottleTimesMinutes.length > count && count >= 1) {
      settings = settings.copyWith(
        bottleTimesMinutes: settings.bottleTimesMinutes.sublist(0, count),
      );
    }
    return settings;
  }

  /// Copie avec l'horaire [index] remplacé par [minutes], retriée ; `null` si
  /// la grille obtenue est invalide (horaire trop proche d'un autre).
  CareSettings? withBottleTime(int index, int minutes) {
    final times = [...bottleTimesMinutes]..[index] = minutes;
    times.sort();
    return bottleTimesAreValid(times)
        ? copyWith(bottleTimesMinutes: times)
        : null;
  }

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
