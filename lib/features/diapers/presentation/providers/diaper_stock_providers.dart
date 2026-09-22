import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/diapers/data/repositories/firestore_diaper_stock_repository.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock_status.dart';
import 'package:colette/features/diapers/domain/repositories/diaper_stock_repository.dart';
import 'package:colette/features/diapers/domain/use_cases/compute_diaper_stock_status.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diaper_stock_providers.g.dart';

/// Sans état : `keepAlive` comme les autres repositories.
@Riverpod(keepAlive: true)
DiaperStockRepository diaperStockRepository(Ref ref) =>
    FirestoreDiaperStockRepository(ref.watch(firestoreProvider));

/// Stock du foyer courant ; `null` sans foyer ou tant qu'il n'est pas renseigné.
@riverpod
Stream<DiaperStock?> diaperStock(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(null);
  return ref.watch(diaperStockRepositoryProvider).watchStock(code);
}

/// Restant et alerte ; `null` tant que le stock n'est pas renseigné.
@riverpod
DiaperStockStatus? diaperStockStatus(Ref ref) {
  final stock = ref.watch(diaperStockProvider).value;
  if (stock == null) return null;
  final changes =
      ref.watch(diaperChangesSinceProvider(stock.countedAt)).value ?? 0;
  return const ComputeDiaperStockStatus()(
    stock: stock,
    changesSinceCount: changes,
  );
}
