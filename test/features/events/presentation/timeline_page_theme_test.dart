import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/pages/timeline_page.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/widgets/day_header_delegate.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/in_memory_household_local_store.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  // Régression : la feuille modale ré-attache la page, et l'en-tête épinglé
  // perdait alors sa dépendance au thème.
  testWidgets('en-tête suit le thème après ouverture/fermeture de la feuille', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 21, 14);
    final repo = MockEventsRepository();
    when(() => repo.watchLatest(any(), limit: any(named: 'limit'))).thenAnswer(
      (_) => Stream.value([
        makeEvent(id: 'e', startAt: DateTime(2026, 9, 21, 9), pee: true),
      ]),
    );
    final mode = ValueNotifier(ThemeMode.dark);
    addTearDown(mode.dispose);
    const themeService = ThemeService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          eventsRepositoryProvider.overrideWithValue(repo),
          clockProvider.overrideWithValue(FixedClock(now)),
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
          ),
        ],
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: mode,
          builder: (context, value, _) => MaterialApp(
            theme: themeService.light(),
            darkTheme: themeService.dark(),
            themeMode: value,
            locale: const Locale('fr'),
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: const TimelinePage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Color headerColor() {
      final header = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is SliverPersistentHeader && w.delegate is DayHeaderDelegate,
        ),
        matching: find.byType(ColoredBox),
      );
      return tester.widget<ColoredBox>(header.first).color;
    }

    expect(headerColor(), AppColors.pageBackground.dark);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(EventFormSheet), findsOneWidget);
    Navigator.of(tester.element(find.byType(EventFormSheet))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(EventFormSheet), findsNothing);

    mode.value = ThemeMode.light;
    await tester.pumpAndSettle();
    expect(headerColor(), AppColors.pageBackground.light);
  });
}
