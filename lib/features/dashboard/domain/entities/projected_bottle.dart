import 'package:freezed_annotation/freezed_annotation.dart';

part 'projected_bottle.freezed.dart';

/// Biberon prévu dans la timeline des 24 prochaines heures.
@freezed
abstract class ProjectedBottle with _$ProjectedBottle {
  const factory ProjectedBottle({
    /// Heure prévue de la prise.
    required DateTime at,
    required int suggestedMl,
  }) = _ProjectedBottle;
}
