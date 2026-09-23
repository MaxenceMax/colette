import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/presentation/pages/sleep_page.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_card.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_week_chart.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_sleep_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 14, 47);

  List<Override> overrides(FakeSleepRepository repo) => [
    sleepRepositoryProvider.overrideWithValue(repo),
    clockProvider.overrideWithValue(FixedClock(now)),
    minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
    babyProfileProvider.overrideWith(
      (ref) =>
          Stream.value(BabyProfile(name: 'C', birthDate: DateTime(2026, 9, 1))),
    ),
  ];

  Future<void> pumpThemed(
    WidgetTester tester,
    Widget child,
    ThemeMode mode,
    FakeSleepRepository repo,
  ) async {
    const themeService = ThemeService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(repo),
        child: MaterialApp(
          theme: themeService.light(),
          darkTheme: themeService.dark(),
          themeMode: mode,
          locale: const Locale('fr'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('SleepCard endormi·e : aucune exception en clair et en sombre', (
    tester,
  ) async {
    final repo = FakeSleepRepository([
      makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 14, 5)),
    ]);

    await pumpThemed(
      tester,
      const Scaffold(body: SleepCard()),
      ThemeMode.light,
      repo,
    );
    expect(tester.takeException(), isNull);

    await pumpThemed(
      tester,
      const Scaffold(body: SleepCard()),
      ThemeMode.dark,
      repo,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'SleepPage avec une nuit et deux siestes : aucune exception, piste au thème',
    (tester) async {
      final repo = FakeSleepRepository([
        makeSleep(
          id: 'n',
          kind: SleepKind.night,
          startAt: DateTime(2026, 9, 22, 21),
          endAt: DateTime(2026, 9, 23, 7),
        ),
        makeSleep(
          id: 'a',
          startAt: DateTime(2026, 9, 23, 9),
          endAt: DateTime(2026, 9, 23, 10, 30),
        ),
        makeSleep(
          id: 'b',
          startAt: DateTime(2026, 9, 23, 13),
          endAt: DateTime(2026, 9, 23, 13, 45),
        ),
      ]);

      Color trackColor() {
        // Material ajoute un second CustomPaint (couche d'effets d'encre) :
        // on filtre sur le type du painter plutôt que sur le seul widget.
        final painter = tester
            .widgetList<CustomPaint>(
              find.descendant(
                of: find.byType(SleepWeekRow).first,
                matching: find.byType(CustomPaint),
              ),
            )
            .map((w) => w.painter)
            .whereType<SleepRowPainter>()
            .single;
        return painter.track;
      }

      await pumpThemed(tester, const SleepPage(), ThemeMode.light, repo);
      expect(tester.takeException(), isNull);
      expect(trackColor(), AppColors.surfaceContainer.light);

      await pumpThemed(tester, const SleepPage(), ThemeMode.dark, repo);
      expect(tester.takeException(), isNull);
      expect(trackColor(), AppColors.surfaceContainer.dark);
    },
  );
}
