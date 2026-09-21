import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/baby/data/repositories/firestore_baby_repository.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'baby_providers.g.dart';

@riverpod
BabyRepository babyRepository(Ref ref) =>
    FirestoreBabyRepository(ref.watch(firestoreProvider));

/// Profil du bébé du foyer courant.
@riverpod
Stream<BabyProfile?> babyProfile(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(null);
  return ref.watch(babyRepositoryProvider).watchProfile(code);
}

/// Pesées du foyer courant, de la plus récente à la plus ancienne.
@riverpod
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
