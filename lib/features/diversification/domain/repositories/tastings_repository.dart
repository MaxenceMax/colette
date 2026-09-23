import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:fpdart/fpdart.dart';

/// Dégustations d'un foyer.
abstract interface class TastingsRepository {
  /// Toutes les dégustations, de la plus récente à la plus ancienne.
  Stream<List<Tasting>> watchAll(String householdCode);

  /// Crée ou remplace la dégustation (clé : `tasting.id`).
  Future<Either<Failure, void>> save(String householdCode, Tasting tasting);

  Future<Either<Failure, void>> delete(String householdCode, String tastingId);
}
