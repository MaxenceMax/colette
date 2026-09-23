import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tasting.freezed.dart';

/// Essai d'un aliment. [id] vide tant que la dégustation n'est pas enregistrée.
@freezed
abstract class Tasting with _$Tasting {
  const factory Tasting({
    required String id,
    required String foodId,
    required DateTime at,
    Liking? liking,
    @Default(false) bool hadReaction,
    String? note,
  }) = _Tasting;
}
