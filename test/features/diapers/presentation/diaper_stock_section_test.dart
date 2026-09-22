import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/repositories/diaper_stock_repository.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/diapers/presentation/widgets/diaper_stock_section.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockDiaperStockRepository extends Mock implements DiaperStockRepository {}

void main() {
  final countedAt = DateTime(2026, 9, 20, 10);
  final stock = DiaperStock(
    count: 44,
    countedAt: countedAt,
    alertThreshold: 10,
  );

  setUpAll(() => registerFallbackValue(stock));

  Future<MockDiaperStockRepository> pumpSection(
    WidgetTester tester, {
    required DiaperStock? current,
    required int changes,
  }) async {
    final repo = MockDiaperStockRepository();
    when(() => repo.saveStock(any(), any()))
        .thenAnswer((_) async => right(null));
    when(() => repo.saveThreshold(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      const Scaffold(body: SingleChildScrollView(child: DiaperStockSection())),
      overrides: [
        diaperStockRepositoryProvider.overrideWithValue(repo),
        diaperStockProvider.overrideWith((ref) => Stream.value(current)),
        diaperChangesSinceProvider.overrideWith(
          (ref, from) => Stream.value(changes),
        ),
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 22, 15))),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    return repo;
  }

  testWidgets('affiche le restant et le stepper de seuil', (tester) async {
    await pumpSection(tester, current: stock, changes: 4);
    expect(find.text('Il reste 40 couches'), findsOneWidget);
    expect(find.text('Recompter'), findsOneWidget);
    expect(find.text('+ paquet'), findsOneWidget);
    expect(find.byType(IntStepperRow), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('sans stock : « Stock non renseigné » et pas de stepper', (
    tester,
  ) async {
    await pumpSection(tester, current: null, changes: 0);
    expect(find.text('Stock non renseigné'), findsOneWidget);
    expect(find.byType(IntStepperRow), findsNothing);
    expect(find.text('Recompter'), findsOneWidget);
  });

  testWidgets('le stepper enregistre le seuil', (tester) async {
    final repo = await pumpSection(tester, current: stock, changes: 0);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.remove));
    await tester.pumpAndSettle();
    verify(() => repo.saveThreshold('ABCDEFGH', 9)).called(1);
    verifyNever(() => repo.saveStock(any(), any()));
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('« Recompter » ouvre la feuille', (tester) async {
    await pumpSection(tester, current: stock, changes: 0);
    await tester.tap(find.text('Recompter'));
    await tester.pumpAndSettle();
    expect(find.text('Couches en stock'), findsOneWidget);
  });

  testWidgets('comptage en erreur : message et « + paquet » désactivé', (
    tester,
  ) async {
    final repo = MockDiaperStockRepository();
    await pumpApp(
      tester,
      const Scaffold(body: SingleChildScrollView(child: DiaperStockSection())),
      overrides: [
        diaperStockRepositoryProvider.overrideWithValue(repo),
        diaperStockProvider.overrideWith((ref) => Stream.value(stock)),
        diaperChangesSinceProvider.overrideWith(
          (ref, from) => Stream<int>.error(Exception('index manquant')),
        ),
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 22, 15))),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    expect(find.text('Une erreur est survenue.'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '+ paquet'))
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Recompter'))
          .enabled,
      isTrue,
    );
  });

  testWidgets('« + paquet » ajoute au restant, pas au comptage', (
    tester,
  ) async {
    final repo = await pumpSection(tester, current: stock, changes: 4);
    await tester.tap(find.text('+ paquet'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '10');
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveStock('ABCDEFGH', captureAny())).captured.single
            as DiaperStock;
    expect(saved.count, 50);
    expect(saved.lastPackSize, 10);
  });
}
