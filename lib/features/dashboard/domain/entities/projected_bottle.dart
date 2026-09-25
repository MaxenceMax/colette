import 'package:freezed_annotation/freezed_annotation.dart';

part 'projected_bottle.freezed.dart';

/// Biberon prévu dans la timeline des 24 prochaines heures.
@freezed
abstract class ProjectedBottle with _$ProjectedBottle {
  const factory ProjectedBottle({
    /// Heure supposée de la prise : le centre du plan pour le prochain
    /// biberon, le début de la fourchette pour les suivants.
    required DateTime at,
    required DateTime windowStart,
    required DateTime windowEnd,
    required int suggestedMl,
  }) = _ProjectedBottle;
}
