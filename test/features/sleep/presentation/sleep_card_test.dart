import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_sleep_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 14, 47);

  List<Override> overrides(FakeSleepRepository repo, {DateTime? birth}) => [
    sleepRepositoryProvider.overrideWithValue(repo),
    clockProvider.overrideWithValue(FixedClock(now)),
    minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
    idGeneratorProvider.overrideWithValue(const FixedIdGenerator('new')),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
    babyProfileProvider.overrideWith(
      (ref) => Stream.value(
        BabyProfile(name: 'C', birthDate: birth ?? DateTime(2026, 9, 1)),
      ),
    ),
  ];

  Future<void> pump(
    WidgetTester tester,
    FakeSleepRepository repo, {
    DateTime? birth,
  }) => pumpApp(
    tester,
    const Scaffold(body: SleepCard()),
    overrides: overrides(repo, birth: birth),
  );

  testWidgets('endormi·e : durée, type, heure, bouton Réveillé·e', (
    tester,
  ) async {
    final repo = FakeSleepRepository([
      makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 14, 5)),
    ]);
    await pump(tester, repo);
    expect(find.text('Dort depuis 42 min'), findsOneWidget);
    expect(find.text('Sieste · depuis 14h05'), findsOneWidget);
    expect(
      find.text('Sur 24 h : 42 min · repère OMS 14 à 17 h'),
      findsOneWidget,
    );
    await tester.tap(find.text('Réveillé·e'));
    await tester.pumpAndSettle();
    expect(repo.lastWakeUp!.close.endAt, now);
  });

  testWidgets(
    'éveillé·e : depuis la fin du dernier sommeil, bouton Endormi·e',
    (tester) async {
      final repo = FakeSleepRepository([
        makeSleep(
          id: 'a',
          startAt: DateTime(2026, 9, 23, 12),
          endAt: DateTime(2026, 9, 23, 13, 37),
        ),
      ]);
      await pump(tester, repo);
      expect(find.text('Éveillé·e depuis 1 h 10'), findsOneWidget);
      await tester.tap(find.text('Endormi·e'));
      await tester.pumpAndSettle();
      expect(repo.saved.single.endAt, isNull);
    },
  );

  testWidgets('aucun sommeil : invitation', (tester) async {
    await pump(tester, FakeSleepRepository());
    expect(find.text('Aucun sommeil noté'), findsOneWidget);
    expect(find.text('Endormi·e'), findsOneWidget);
  });

  testWidgets('réveil oublié au-delà de 16 h', (tester) async {
    final repo = FakeSleepRepository([
      makeSleep(
        id: 'o',
        kind: SleepKind.night,
        startAt: DateTime(2026, 9, 22, 21),
      ),
    ]);
    await pump(tester, repo);
    expect(find.text('Réveil oublié ?'), findsOneWidget);
    await tester.tap(find.text('Saisir le réveil'));
    await tester.pumpAndSettle();
    // Le sélecteur de fin s'ouvre par-dessus la feuille (pickEndOnOpen).
    expect(find.text('Modifier le sommeil'), findsOneWidget);
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
  });

  testWidgets('au-delà de 2 ans : total sans repère OMS', (tester) async {
    await pump(tester, FakeSleepRepository(), birth: DateTime(2024, 1, 1));
    expect(find.text('Sur 24 h : 0 min'), findsOneWidget);
  });
}
