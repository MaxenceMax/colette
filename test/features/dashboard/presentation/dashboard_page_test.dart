import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 9, 10, 12);
  final profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1));
  final bottle = makeEvent(
    id: 'b',
    startAt: DateTime(2026, 9, 10, 8),
    bottleMl: 60,
  );
  final adrigyl = makeEvent(
    id: 'a',
    startAt: DateTime(2026, 9, 10, 9),
    adrigyl: true,
    diaperChange: true,
  );

  testWidgets(
    'affiche l\'âge, le prochain biberon, les tâches et les compteurs',
    (tester) async {
      await pumpApp(
        tester,
        const DashboardPage(),
        overrides: [
          clockProvider.overrideWithValue(FixedClock(now)),
          minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
          ),
          babyProfileProvider.overrideWith((ref) => Stream.value(profile)),
          weightsProvider.overrideWith(
            (ref) => Stream.value([
              WeightEntry(
                id: 'w',
                measuredAt: DateTime(2026, 9, 9),
                grams: 3600,
              ),
            ]),
          ),
          todayEventsProvider.overrideWith(
            (ref) => Stream.value([adrigyl, bottle]),
          ),
          latestBottleProvider.overrideWith((ref) => Stream.value(bottle)),
          latestBathProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );

      expect(find.text('Colette a 9 jours'), findsOneWidget);
      expect(find.text('Prochain biberon'), findsOneWidget);
      expect(find.text('70 ml'), findsOneWidget);
      expect(find.text('en retard de 60 min'), findsOneWidget);
      expect(find.text('fait à 09h00'), findsOneWidget);
      expect(find.text('Soin des yeux'), findsOneWidget);
      expect(find.text('Bain'), findsOneWidget);
      expect(find.text('couches'), findsOneWidget);
    },
  );
}
