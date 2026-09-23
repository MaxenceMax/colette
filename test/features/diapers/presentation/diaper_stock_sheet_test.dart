import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/repositories/diaper_stock_repository.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/diapers/presentation/widgets/diaper_stock_sheet.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockDiaperStockRepository extends Mock implements DiaperStockRepository {}

void main() {
  final now = DateTime(2026, 9, 22, 15);
  final stock = DiaperStock(
    count: 44,
    countedAt: DateTime(2026, 9, 20, 10),
    lastPackSize: 30,
  );

  setUpAll(() => registerFallbackValue(stock));

  Future<MockDiaperStockRepository> pumpSheet(
    WidgetTester tester, {
    required DiaperStockSheetMode mode,
    required DiaperStock? current,
    required int remaining,
  }) async {
    final repo = MockDiaperStockRepository();
    when(() => repo.saveStock(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDiaperStockSheet(
              context,
              mode: mode,
              current: current,
              remaining: remaining,
            ),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: [
        diaperStockRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('recompter enregistre la valeur saisie', (tester) async {
    final repo = await pumpSheet(
      tester,
      mode: DiaperStockSheetMode.recount,
      current: stock,
      remaining: 40,
    );
    expect(find.text('Couches en stock'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '25');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveStock('ABCDEFGH', captureAny())).captured.single
            as DiaperStock;
    expect(saved.count, 25);
    expect(saved.countedAt, now);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('+ paquet est prérempli et ajoute au restant', (tester) async {
    final repo = await pumpSheet(
      tester,
      mode: DiaperStockSheetMode.addPack,
      current: stock,
      remaining: 7,
    );
    expect(find.text('Taille du paquet'), findsOneWidget);
    expect(find.text('Couches dans le paquet'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '30',
    );
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveStock('ABCDEFGH', captureAny())).captured.single
            as DiaperStock;
    expect(saved.count, 37);
    expect(saved.lastPackSize, 30);
  });

  testWidgets('+ paquet sans stock est prérempli avec la taille par défaut', (
    tester,
  ) async {
    final repo = await pumpSheet(
      tester,
      mode: DiaperStockSheetMode.addPack,
      current: null,
      remaining: 0,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '44',
    );
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveStock('ABCDEFGH', captureAny())).captured.single
            as DiaperStock;
    expect(saved.count, 44);
    expect(saved.lastPackSize, 44);
  });

  testWidgets('un champ vide laisse la feuille ouverte', (tester) async {
    final repo = await pumpSheet(
      tester,
      mode: DiaperStockSheetMode.recount,
      current: null,
      remaining: 0,
    );
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.saveStock(any(), any()));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('un échec du repository laisse la feuille ouverte', (
    tester,
  ) async {
    final repo = await pumpSheet(
      tester,
      mode: DiaperStockSheetMode.recount,
      current: stock,
      remaining: 40,
    );
    when(() => repo.saveStock(any(), any()))
        .thenAnswer((_) async => left(const NetworkFailure()));
    await tester.enterText(find.byType(TextField), '25');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('le bouton est désactivé pendant l\'écriture', (tester) async {
    final completer = Completer<Either<Failure, void>>();
    final repo = await pumpSheet(
      tester,
      mode: DiaperStockSheetMode.recount,
      current: stock,
      remaining: 40,
    );
    when(() => repo.saveStock(any(), any()))
        .thenAnswer((_) => completer.future);
    await tester.enterText(find.byType(TextField), '25');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).enabled,
      isFalse,
    );
    completer.complete(right(null));
    await tester.pumpAndSettle();
  });
}
