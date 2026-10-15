import 'package:colette/core/result/failure.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:fpdart/fpdart.dart';

/// Dents notées d'un foyer.
abstract interface class TeethRepository {
  /// Dents notées, dans un ordre quelconque.
  Stream<List<ToothRecord>> watchTeeth(String householdCode);

  /// Remplace entièrement ce qui est noté pour la dent.
  Future<Either<Failure, void>> saveTooth(
    String householdCode,
    ToothRecord record,
  );

  /// Supprime ce qui est noté pour la dent.
  Future<Either<Failure, void>> deleteTooth(
    String householdCode,
    ToothId toothId,
  );
}
