import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_settings.freezed.dart';

/// Fréquences des soins attendus chaque jour et cible de lait ajustée.
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

    /// Cible journalière forcée en ml ; `null` = calcul OMS.
    int? dailyTargetMl,
  }) = _CareSettings;

  static const minDailyTargetMl = 100;
  static const maxDailyTargetMl = 1500;
  static const dailyTargetStepMl = 10;
}
