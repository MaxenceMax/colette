import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_settings.freezed.dart';

/// Fréquences des soins attendus chaque jour.
@freezed
abstract class CareSettings with _$CareSettings {
  const factory CareSettings({
    @Default(1) int adrigylPerDay,
    @Default(1) int eyeCarePerDay,
    @Default(1) int noseCarePerDay,
    @Default(true) bool umbilicalCareEnabled,
    @Default(2) int bathEveryDays,
    @Default(8) int feedsPerDay,
  }) = _CareSettings;
}
