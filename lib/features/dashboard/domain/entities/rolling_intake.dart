import 'package:freezed_annotation/freezed_annotation.dart';

part 'rolling_intake.freezed.dart';

/// Biberons donnés sur les dernières 24 heures glissantes.
@freezed
abstract class RollingIntake with _$RollingIntake {
  const factory RollingIntake({required int bottles, required int ml}) =
      _RollingIntake;
}
