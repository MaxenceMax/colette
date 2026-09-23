import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/feeding_plan_snapshot.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:fpdart/fpdart.dart';

/// Profil du bébé, pesées et résumé du plan biberons.
abstract interface class BabyRepository {
  Stream<BabyProfile?> watchProfile(String householdCode);

  Future<Either<Failure, void>> saveProfile(
    String householdCode,
    BabyProfile profile,
  );

  /// Pesées triées de la plus récente à la plus ancienne.
  Stream<List<WeightEntry>> watchWeights(String householdCode);

  Future<Either<Failure, void>> addWeight(
    String householdCode,
    WeightEntry entry,
  );

  Future<Either<Failure, void>> deleteWeight(
    String householdCode,
    String weightId,
  );

  /// Mesures de croissance triées de la plus récente à la plus ancienne.
  Stream<List<GrowthMeasurement>> watchMeasurements(String householdCode);

  /// Ajoute ou remplace entièrement la mesure [measurement].
  Future<Either<Failure, void>> saveMeasurement(
    String householdCode,
    GrowthMeasurement measurement,
  );

  Future<Either<Failure, void>> deleteMeasurement(
    String householdCode,
    String measurementId,
  );

  Future<Either<Failure, void>> saveFeedingPlan(
    String householdCode,
    FeedingPlanSnapshot snapshot,
  );
}
