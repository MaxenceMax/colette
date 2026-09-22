import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:fpdart/fpdart.dart';

/// Stock de couches du foyer.
abstract interface class DiaperStockRepository {
  /// `null` tant que le stock n'a jamais été renseigné.
  Stream<DiaperStock?> watchStock(String householdCode);

  Future<Either<Failure, void>> saveStock(
    String householdCode,
    DiaperStock stock,
  );
}
