import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/baby/data/repositories/firestore_baby_repository.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/growth_trend.dart';
import 'package:colette/features/baby/domain/entities/who_percentiles.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/domain/use_cases/compute_growth_trend.dart';
import 'package:colette/features/baby/domain/use_cases/compute_who_reference.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'baby_providers.g.dart';

/// Sans état : `keepAlive` car consommé par `feedingPlanSyncProvider` (keepAlive).
@Riverpod(keepAlive: true)
BabyRepository babyRepository(Ref ref) =>
    FirestoreBabyRepository(ref.watch(firestoreProvider));

/// Profil du bébé du foyer courant.
@Riverpod(retry: noRetry)
Stream<BabyProfile?> babyProfile(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(null);
  return ref.watch(babyRepositoryProvider).watchProfile(code);
}

/// Mesures de croissance du foyer courant, de la plus récente à la plus ancienne.
@Riverpod(retry: noRetry)
Stream<List<GrowthMeasurement>> measurements(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  return ref.watch(babyRepositoryProvider).watchMeasurements(code);
}

/// Mesure avec poids la plus récente, ou `null`.
@riverpod
GrowthMeasurement? latestWeight(Ref ref) => GrowthMetric.weight.latestOf(
  ref.watch(measurementsProvider).value ?? const [],
);

/// Dernière valeur de [metric] et évolution depuis la précédente, ou `null`.
@riverpod
GrowthTrend? growthTrend(Ref ref, GrowthMetric metric) =>
    const ComputeGrowthTrend()(
      metric,
      ref.watch(measurementsProvider).value ?? const [],
    );

/// Percentiles OMS de [metric] sur la période de ses mesures, une journée de
/// marge de chaque côté ; vide sans mesure, sans profil ou sans sexe renseigné.
@riverpod
List<WhoPercentiles> whoReference(Ref ref, GrowthMetric metric) {
  final profile = ref.watch(babyProfileProvider).value;
  final sex = profile?.sex;
  final series = metric.seriesOf(
    ref.watch(measurementsProvider).value ?? const [],
  );
  if (profile == null || sex == null || series.isEmpty) return const [];
  return const ComputeWhoReference()(
    metric: metric,
    sex: sex,
    birthDate: profile.birthDate,
    from: series.first.at.startOfPreviousDay,
    to: series.last.at.startOfNextDay,
  );
}
