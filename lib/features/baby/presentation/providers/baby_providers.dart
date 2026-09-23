import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/baby/data/repositories/firestore_baby_repository.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/domain/entities/weight_trend.dart';
import 'package:colette/features/baby/domain/entities/who_weight_percentiles.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/domain/use_cases/compute_weight_trend.dart';
import 'package:colette/features/baby/domain/use_cases/compute_who_weight_reference.dart';
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

/// Pesées du foyer courant, de la plus récente à la plus ancienne.
@Riverpod(retry: noRetry)
Stream<List<WeightEntry>> weights(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  return ref.watch(babyRepositoryProvider).watchWeights(code);
}

/// Pesée la plus récente, ou `null`.
@riverpod
WeightEntry? latestWeight(Ref ref) {
  final list = ref.watch(weightsProvider).value;
  return list == null || list.isEmpty ? null : list.first;
}

/// Dernière pesée et évolution depuis la précédente, ou `null` sans pesée.
@riverpod
WeightTrend? weightTrend(Ref ref) =>
    const ComputeWeightTrend()(ref.watch(weightsProvider).value ?? const []);

/// Percentiles OMS sur la période des pesées, une journée de marge de chaque
/// côté ; vide sans pesée, sans profil ou sans sexe renseigné.
@riverpod
List<WhoWeightPercentiles> whoWeightReference(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  final sex = profile?.sex;
  final weights = ref.watch(weightsProvider).value ?? const [];
  if (profile == null || sex == null || weights.isEmpty) return const [];
  final dates = weights.map((w) => w.measuredAt).toList()..sort();
  return const ComputeWhoWeightReference()(
    sex: sex,
    birthDate: profile.birthDate,
    from: dates.first.startOfPreviousDay,
    to: dates.last.startOfNextDay,
  );
}
