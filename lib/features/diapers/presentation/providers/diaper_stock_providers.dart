import 'dart:developer' as developer;

import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/diapers/data/repositories/firestore_diaper_stock_repository.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock_status.dart';
import 'package:colette/features/diapers/domain/repositories/diaper_stock_repository.dart';
import 'package:colette/features/diapers/domain/use_cases/compute_diaper_stock_status.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diaper_stock_providers.g.dart';

/// Sans état et partagé : `keepAlive`.
@Riverpod(keepAlive: true)
DiaperStockRepository diaperStockRepository(Ref ref) =>
    FirestoreDiaperStockRepository(ref.watch(firestoreProvider));

/// Stock du foyer courant ; `null` sans foyer ou tant qu'il n'est pas renseigné.
@Riverpod(retry: noRetry)
Stream<DiaperStock?> diaperStock(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(null);
  return ref.watch(diaperStockRepositoryProvider).watchStock(code);
}

/// Restant et alerte. `AsyncData(null)` tant que le stock n'est pas renseigné ;
/// `AsyncLoading` ou `AsyncError` tant que le stock ou le comptage des changes
/// n'est pas disponible, pour ne jamais afficher ni écrire un restant faux.
@riverpod
AsyncValue<DiaperStockStatus?> diaperStockStatus(Ref ref) => switch (ref.watch(
  diaperStockProvider,
)) {
  AsyncError(:final error, :final stackTrace) => _logged(error, stackTrace),
  AsyncData(value: null) => const AsyncData(null),
  AsyncData(value: final stock?) => switch (ref.watch(
    diaperChangesSinceProvider(stock.countedAt),
  )) {
    AsyncData(value: final changes) => AsyncData(
      const ComputeDiaperStockStatus()(
        stock: stock,
        changesSinceCount: changes,
      ),
    ),
    AsyncError(:final error, :final stackTrace) => _logged(error, stackTrace),
    _ => const AsyncLoading(),
  },
  _ => const AsyncLoading(),
};

/// Journalise l'échec (un comptage en erreur rendrait le stock silencieusement faux).
AsyncError<DiaperStockStatus?> _logged(Object error, StackTrace stackTrace) {
  developer.log(
    'Diaper stock status failed',
    error: error,
    stackTrace: stackTrace,
    name: 'colette',
  );
  return AsyncError(error, stackTrace);
}
