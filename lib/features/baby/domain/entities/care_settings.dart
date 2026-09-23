import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_settings.freezed.dart';

/// Fréquences des soins attendus, cible de lait ajustée et horaires de nuit.
@freezed
abstract class CareSettings with _$CareSettings {
  const CareSettings._();

  const factory CareSettings({
    @Default(1) int adrigylPerDay,
    @Default(1) int eyeCarePerDay,
    @Default(1) int noseCarePerDay,
    @Default(3) int umbilicalCarePerDay,
    @Default(2) int bathEveryDays,
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
}
