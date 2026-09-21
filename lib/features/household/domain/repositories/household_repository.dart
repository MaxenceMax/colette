import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/domain/entities/household.dart';
import 'package:fpdart/fpdart.dart';

/// Création et jonction d'un foyer.
abstract interface class HouseholdRepository {
  Future<Either<Failure, Household>> create(String code);

  /// [NotFoundFailure] si le code n'existe pas.
  Future<Either<Failure, Household>> join(String code);
}
