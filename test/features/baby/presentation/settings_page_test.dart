import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/pages/settings_page.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('affiche le profil, les pesées et le code foyer', (tester) async {
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
      ],
    );
    expect(find.text('Colette'), findsOneWidget);
    expect(find.text('3600 g'), findsOneWidget);
    expect(find.text('Soins attendus'), findsOneWidget);
    // La section Foyer est sous la ligne de flottaison de la taille de test
    // par défaut (800x600) : la ListView ne construit pas ses slivers hors
    // écran tant qu'on ne défile pas jusqu'à eux.
    await tester.scrollUntilVisible(find.text('ABCDEFGH'), 300);
    expect(find.text('ABCDEFGH'), findsOneWidget);
  });
}
