import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/repositories/diaper_stock_repository.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_controller.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockDiaperStockRepository extends Mock implements DiaperStockRepository {}

void main() {
  late MockDiaperStockRepository repo;
  late ProviderContainer container;
  final now = DateTime(2026, 9, 22, 15);
  final countedAt = DateTime(2026, 9, 20, 10);
  final stock = DiaperStock(
    count: 44,
    countedAt: countedAt,
    alertThreshold: 12,
    lastPackSize: 30,
  );

  setUpAll(() => registerFallbackValue(stock));

  setUp(() {
    repo = MockDiaperStockRepository();
    when(() => repo.saveStock(any(), any()))
        .thenAnswer((_) async => right(null));
    when(() => repo.saveThreshold(any(), any()))
        .thenAnswer((_) async => right(null));
    container = ProviderContainer(
      overrides: [
        diaperStockRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  DiaperStockController controller() =>
      container.read(diaperStockControllerProvider.notifier);

  DiaperStock captured() =>
      verify(() => repo.saveStock('ABCDEFGH', captureAny())).captured.single
          as DiaperStock;

  test('recount écrit count et countedAt = now', () async {
    expect(await controller().recount(stock, 20), isTrue);
    final saved = captured();
    expect(saved.count, 20);
    expect(saved.countedAt, now);
    expect(saved.alertThreshold, 12);
  });

  test('recount sans stock crée le stock avec les défauts', () async {
    expect(await controller().recount(null, 20), isTrue);
    final saved = captured();
    expect(saved, DiaperStock(count: 20, countedAt: now));
  });

  test('addPack écrit restant + taille et mémorise la taille', () async {
    expect(await controller().addPack(stock, remaining: 7, size: 50), isTrue);
    final saved = captured();
    expect(saved.count, 57);
    expect(saved.countedAt, now);
    expect(saved.lastPackSize, 50);
  });

  test('addPack sans stock part d\'un restant à 0', () async {
    expect(await controller().addPack(null, remaining: 0, size: 44), isTrue);
    expect(captured().count, 44);
  });

  test('setThreshold écrit uniquement le seuil', () async {
    expect(await controller().setThreshold(5), isTrue);
    verify(() => repo.saveThreshold('ABCDEFGH', 5));
    verifyNever(() => repo.saveStock(any(), any()));
  });

  test('recount refuse une valeur hors bornes', () async {
    expect(await controller().recount(stock, 10000), isFalse);
    expect(
      container.read(diaperStockControllerProvider).error,
      isA<ValidationFailure>().having(
        (f) => f.reason,
        'reason',
        ValidationReason.invalidDiaperCount,
      ),
    );
    verifyNever(() => repo.saveStock(any(), any()));
  });

  test('addPack refuse une taille nulle', () async {
    expect(await controller().addPack(stock, remaining: 7, size: 0), isFalse);
    verifyNever(() => repo.saveStock(any(), any()));
    expect(
      container.read(diaperStockControllerProvider).error,
      isA<ValidationFailure>().having(
        (f) => f.reason,
        'reason',
        ValidationReason.invalidDiaperCount,
      ),
    );
  });

  test('addPack refuse un dépassement du stock maximal', () async {
    expect(
      await controller().addPack(stock, remaining: 9990, size: 20),
      isFalse,
    );
    verifyNever(() => repo.saveStock(any(), any()));
  });

  test('setThreshold refuse une valeur hors bornes', () async {
    expect(await controller().setThreshold(1000), isFalse);
    verifyNever(() => repo.saveStock(any(), any()));
    verifyNever(() => repo.saveThreshold(any(), any()));
  });

  test('recount refuse une valeur négative', () async {
    expect(await controller().recount(stock, -1), isFalse);
    verifyNever(() => repo.saveStock(any(), any()));
  });

  test('sans code foyer, rien n\'est écrit', () async {
    final noHouseholdContainer = ProviderContainer(
      overrides: [
        diaperStockRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(),
        ),
      ],
    );
    addTearDown(noHouseholdContainer.dispose);
    final noHouseholdController = noHouseholdContainer.read(
      diaperStockControllerProvider.notifier,
    );
    expect(await noHouseholdController.recount(stock, 20), isFalse);
    verifyNever(() => repo.saveStock(any(), any()));
  });

  test('un échec du repository est exposé dans l\'état', () async {
    when(() => repo.saveStock(any(), any()))
        .thenAnswer((_) async => left(const NetworkFailure()));
    expect(await controller().recount(stock, 20), isFalse);
    expect(
      container.read(diaperStockControllerProvider).error,
      isA<NetworkFailure>(),
    );
  });
}
