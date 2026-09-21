import 'package:freezed_annotation/freezed_annotation.dart';

part 'baby_age.freezed.dart';

/// Unité d'affichage de l'âge.
enum BabyAgeUnit { days, weeks, months }

/// Âge du bébé dans l'unité la plus parlante.
@freezed
abstract class BabyAge with _$BabyAge {
  const factory BabyAge({required BabyAgeUnit unit, required int count}) =
      _BabyAge;
}
