import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/teeth/data/repositories/firestore_teeth_repository.dart';
import 'package:colette/features/teeth/domain/entities/teeth_summary.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/repositories/teeth_repository.dart';
import 'package:colette/features/teeth/domain/use_cases/compute_teeth_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'teeth_providers.g.dart';

/// Sans état : `keepAlive` comme les autres dépôts Firestore.
@Riverpod(keepAlive: true)
TeethRepository teethRepository(Ref ref) =>
    FirestoreTeethRepository(ref.watch(firestoreProvider));

/// Dents notées du foyer courant, indexées par numéro.
@Riverpod(retry: noRetry)
Stream<Map<ToothId, ToothRecord>> teeth(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const {});
  return ref
      .watch(teethRepositoryProvider)
      .watchTeeth(code)
      .map((records) => {for (final r in records) r.toothId: r});
}

/// Résumé pour la carte Santé ; `null` tant que les dents ne sont pas lues.
@riverpod
TeethSummary? teethSummary(Ref ref) => switch (ref.watch(teethProvider)) {
  AsyncData(:final value) => const ComputeTeethSummary()(value),
  _ => null,
};
