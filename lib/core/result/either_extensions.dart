import 'package:fpdart/fpdart.dart';

/// Raccourcis de lecture sur `Either`.
extension EitherX<L, R> on Either<L, R> {
  /// La valeur gauche, ou `null` si c'est un `Right`.
  L? get leftOrNull => fold((l) => l, (_) => null);
}
