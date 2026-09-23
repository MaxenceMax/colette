import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/pages/weight_curve_page.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/who_curves_visibility.dart';
import 'package:colette/features/baby/presentation/widgets/add_weight_sheet.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final weights = [
    GrowthMeasurement(id: 'a', measuredAt: DateTime(2026, 9, 2), grams: 3200),
    GrowthMeasurement(id: 'c', measuredAt: DateTime(2026, 9, 14), grams: 3650),
    GrowthMeasurement(id: 'b', measuredAt: DateTime(2026, 9, 10), grams: 3470),
  ];

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  List<Override> overrides(List<GrowthMeasurement> list, {BabySex? sex}) => [
    sharedPreferencesProvider.overrideWithValue(prefs),
    babyProfileProvider.overrideWith(
      (ref) => Stream.value(
        BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1), sex: sex),
      ),
    ),
    clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 15, 12))),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
    measurementsProvider.overrideWith((ref) => Stream.value(list)),
    // La liste des pesées lit encore `weightsProvider` jusqu'à la tâche 8.
    weightsProvider.overrideWith(
      (ref) => Stream.value([
        for (final m in list)
          WeightEntry(id: m.id, measuredAt: m.measuredAt, grams: m.grams!),
      ]),
    ),
    feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
  ];

  testWidgets('sans pesée : message et bouton d\'ajout, pas de courbe', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const WeightCurvePage(),
      overrides: overrides(const []),
    );
    expect(find.text('Courbe de poids'), findsOneWidget);
    expect(
      find.text(
        'Aucune pesée pour l\'instant. Ajoute-en une pour tracer la courbe.',
      ),
      findsOneWidget,
    );
    expect(find.byType(LineChart), findsNothing);

    await tester.tap(find.text('Ajouter une pesée'));
    await tester.pumpAndSettle();
    expect(find.byType(AddWeightSheet), findsOneWidget);
  });

  testWidgets('avec pesées : dernière pesée, évolution, courbe et liste', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const WeightCurvePage(),
      overrides: overrides(weights),
    );
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('3650 g'), findsWidgets);
    expect(find.text('Pesée du 14 sept. 2026'), findsOneWidget);
    expect(
      find.text('+180\u00A0g en 4\u00A0jours · +45\u00A0g/jour'),
      findsOneWidget,
    );
    expect(find.text('2 sept.'), findsOneWidget);
    expect(find.text('14 sept.'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('3200 g'), 200);
    expect(find.text('3200 g'), findsOneWidget);
  });

  testWidgets('une seule pesée : courbe à un point, « Première pesée »', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const WeightCurvePage(),
      overrides: overrides([weights.first]),
    );
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Première pesée'), findsOneWidget);
    expect(find.text('2 sept.'), findsOneWidget);
  });

  int barCount(WidgetTester tester) =>
      tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData.length;

  testWidgets('courbes OMS cachées par défaut, le bouton les affiche', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const WeightCurvePage(),
      overrides: overrides(weights, sex: BabySex.female),
    );
    expect(barCount(tester), 1);
    expect(find.text('Courbes OMS'), findsOneWidget);

    // L'interrupteur est déjà construit mais sous la ligne de flottaison.
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(barCount(tester), 4);
    expect(
      find.text(
        'Zone teintée : du 3e au 97e percentile OMS. Pointillés : médiane.',
      ),
      findsOneWidget,
    );
    expect(prefs.getBool(WhoCurvesVisibility.prefsKey), isTrue);
  });

  testWidgets('choix mémorisé : courbes OMS affichées à l\'ouverture', (
    tester,
  ) async {
    await prefs.setBool(WhoCurvesVisibility.prefsKey, true);
    await pumpApp(
      tester,
      const WeightCurvePage(),
      overrides: overrides(weights, sex: BabySex.male),
    );
    expect(barCount(tester), 4);
  });

  testWidgets('sans sexe renseigné : bouton inactif et invitation', (
    tester,
  ) async {
    await prefs.setBool(WhoCurvesVisibility.prefsKey, true);
    await pumpApp(
      tester,
      const WeightCurvePage(),
      overrides: overrides(weights),
    );
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(
      find.text(
        'Renseigne le sexe du bébé dans les Réglages pour les afficher.',
      ),
      findsOneWidget,
    );
    expect(barCount(tester), 1);
  });
}
