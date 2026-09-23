import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/presentation/pages/sleep_page.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_week_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_sleep_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 16);

  Future<void> pump(WidgetTester tester, FakeSleepRepository repo) => pumpApp(
    tester,
    const SleepPage(),
    overrides: [
      sleepRepositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(FixedClock(now)),
      minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
      householdLocalStoreProvider.overrideWithValue(
        InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
      ),
      babyProfileProvider.overrideWith(
        (ref) => Stream.value(
          BabyProfile(name: 'C', birthDate: DateTime(2026, 9, 1)),
        ),
      ),
    ],
  );

  testWidgets('sept lignes, moyenne, repère et détail d\'aujourd\'hui', (
    tester,
  ) async {
    final repo = FakeSleepRepository([
      makeSleep(
        id: 'n',
        kind: SleepKind.night,
        startAt: DateTime(2026, 9, 22, 1),
        endAt: DateTime(2026, 9, 22, 15),
      ),
      makeSleep(
        id: 'a',
        startAt: DateTime(2026, 9, 23, 9),
        endAt: DateTime(2026, 9, 23, 10, 30),
      ),
    ]);
    await pump(tester, repo);
    expect(find.byType(SleepWeekRow), findsNWidgets(7));
    expect(find.text('Moyenne des jours précédents : 14 h'), findsOneWidget);
    expect(
      find.text('Repère OMS à son âge : 14 à 17 h sur 24 h'),
      findsOneWidget,
    );
    expect(find.text('Mercredi 23 septembre'), findsOneWidget);
    expect(find.text('1 h 30'), findsWidgets);
  });

  testWidgets('toucher une ligne sélectionne le jour', (tester) async {
    await pump(
      tester,
      FakeSleepRepository([
        makeSleep(
          id: 'n',
          kind: SleepKind.night,
          startAt: DateTime(2026, 9, 22, 1),
          endAt: DateTime(2026, 9, 22, 15),
        ),
      ]),
    );
    await tester.tap(find.text('mar. 22'));
    await tester.pumpAndSettle();
    expect(find.text('Mardi 22 septembre'), findsOneWidget);
  });

  testWidgets('sans historique : pas de moyenne', (tester) async {
    await pump(tester, FakeSleepRepository());
    expect(find.textContaining('Moyenne'), findsNothing);
  });
}
