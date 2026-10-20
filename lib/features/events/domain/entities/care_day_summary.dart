import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_day_summary.freezed.dart';

/// Bilan d'un jour civil : lait bu, biberons, couches changées, pipis.
@freezed
abstract class CareDaySummary with _$CareDaySummary {
  const CareDaySummary._();

  const factory CareDaySummary({
    @Default(0) int bottleMl,
    @Default(0) int bottleCount,
    @Default(0) int diapers,
    @Default(0) int pee,
  }) = _CareDaySummary;

  /// `true` s'il n'y a ni biberon, ni couche, ni pipi.
  bool get isEmpty => bottleCount == 0 && diapers == 0 && pee == 0;
}
