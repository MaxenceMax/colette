import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/pages/settings_page.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('affiche le profil, les pesées et le code foyer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await pumpApp(
      tester,
      const SettingsPage(),
      overrides: [
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 21, 12))),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
        babyProfileProvider.overrideWith(
          (ref) => Stream.value(
            BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
          ),
        ),
        weightsProvider.overrideWith(
          (ref) => Stream.value([
            WeightEntry(id: 'w', measuredAt: DateTime(2026, 9, 9), grams: 3600),
          ]),
        ),
        currentDeviceProvider.overrideWith((ref) => Stream.value(null)),
        diaperStockProvider.overrideWith((ref) => Stream.value(null)),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    expect(find.text('Colette'), findsOneWidget);
    expect(find.text('3600 g'), findsOneWidget);
    expect(find.text('Soins attendus'), findsOneWidget);
    // La section Couches (et, plus bas, la section Foyer) est sous la ligne
    // de flottaison de la taille de test par défaut (800x600) : la ListView
    // ne construit pas ses slivers hors écran tant qu'on ne défile pas jusqu'à eux.
    // Le finder de Scrollable est fixé explicitement : au fil du défilement,
    // le SegmentedButton de la section Apparence expose lui aussi un
    // Scrollable interne, ce qui rendrait `find.byType(Scrollable)` ambigu.
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Couches'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Couches'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Stock non renseigné'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Stock non renseigné'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ABCDEFGH'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('ABCDEFGH'), findsOneWidget);
    expect(find.text('Apparence'), findsOneWidget);
  });
}
