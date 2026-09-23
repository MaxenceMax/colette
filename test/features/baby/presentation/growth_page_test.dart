import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/presentation/pages/growth_page.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/who_curves_visibility.dart';
import 'package:colette/features/baby/presentation/widgets/growth_measurement_sheet.dart';
import 'package:colette/features/baby/presentation/widgets/growth_trend_summary.dart';
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
  final measurements = [
    GrowthMeasurement(
      id: 'a',
      measuredAt: DateTime(2026, 9, 2),
      grams: 3200,
      lengthMm: 520,
      headCircumferenceMm: 350,
    ),
    GrowthMeasurement(
      id: 'c',
      measuredAt: DateTime(2026, 9, 14),
      grams: 3650,
      lengthMm: 540,
    ),
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
    feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
  ];

  Future<void> selectTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  int barCount(WidgetTester tester) =>
      tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData.length;

  testWidgets('s\'ouvre sur le poids : dernière pesée, évolution, courbe', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const GrowthPage(),
      overrides: overrides(measurements),
    );
    expect(find.text('Croissance'), findsOneWidget);
    final selector = tester.widget<SegmentedButton<GrowthMetric>>(
      find.byType(SegmentedButton<GrowthMetric>),
    );
    expect(selector.selected, {GrowthMetric.weight});
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('3650 g'), findsOneWidget);
    expect(find.text('Pesée du 14 sept. 2026'), findsOneWidget);
    expect(
      // Espaces insécables dans `weightTrendSince` (app_fr.arb).
      find.text('+180 g en 4 jours · +45 g/jour'),
      findsOneWidget,
    );
    expect(find.text('2 sept.'), findsOneWidget);
    expect(find.text('14 sept.'), findsOneWidget);
  });

  testWidgets('onglet Taille : valeur en cm et évolution', (tester) async {
    await pumpApp(
      tester,
      const GrowthPage(),
      overrides: overrides(measurements),
    );
    await selectTab(tester, 'Taille');
    // La graduation de l'axe des ordonnées tombe aussi sur 54,0 cm : on
    // cible la valeur du résumé, pas n'importe quel texte de la page.
    expect(
      find.descendant(
        of: find.byType(GrowthTrendSummary),
        matching: find.text('54,0 cm'),
      ),
      findsOneWidget,
    );
    expect(find.text('Mesure du 14 sept. 2026'), findsOneWidget);
    expect(
      // Espace insécable dans `measurementTrendSinceCm` (app_fr.arb).
      find.text('+2,0 cm en 12 jours'),
      findsOneWidget,
    );
  });

  testWidgets('onglet Périmètre : une seule valeur, « Première mesure »', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const GrowthPage(),
      overrides: overrides(measurements),
    );
    await selectTab(tester, 'Périmètre');
    // La graduation de l'axe des ordonnées tombe aussi sur 35,0 cm : on
    // cible la valeur du résumé, pas n'importe quel texte de la page.
    expect(
      find.descendant(
        of: find.byType(GrowthTrendSummary),
        matching: find.text('35,0 cm'),
      ),
      findsOneWidget,
    );
    expect(find.text('Première mesure'), findsOneWidget);
  });

  testWidgets('grandeur jamais mesurée : état vide et ajout', (tester) async {
    await pumpApp(
      tester,
      const GrowthPage(),
      overrides: overrides([measurements.last]),
    );
    await selectTab(tester, 'Périmètre');
    expect(find.text('Aucun périmètre crânien enregistré'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter une mesure'));
    await tester.pumpAndSettle();
    expect(find.byType(GrowthMeasurementSheet), findsOneWidget);
  });

  testWidgets('sans aucune mesure : état vide du poids', (tester) async {
    await pumpApp(tester, const GrowthPage(), overrides: overrides(const []));
    expect(find.text('Aucun poids enregistré'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('courbes OMS cachées par défaut, le bouton les affiche', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const GrowthPage(),
      overrides: overrides(measurements, sex: BabySex.female),
    );
    expect(barCount(tester), 1);
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(barCount(tester), 4);
    expect(prefs.getBool(WhoCurvesVisibility.prefsKey), isTrue);
  });

  testWidgets('le choix OMS vaut pour toutes les grandeurs', (tester) async {
    await prefs.setBool(WhoCurvesVisibility.prefsKey, true);
    await pumpApp(
      tester,
      const GrowthPage(),
      overrides: overrides(measurements, sex: BabySex.male),
    );
    expect(barCount(tester), 4);
    await selectTab(tester, 'Taille');
    expect(barCount(tester), 4);
  });

  testWidgets('sans sexe renseigné : bouton inactif et invitation', (
    tester,
  ) async {
    await prefs.setBool(WhoCurvesVisibility.prefsKey, true);
    await pumpApp(
      tester,
      const GrowthPage(),
      overrides: overrides(measurements),
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

  testWidgets('la liste des mesures est sous la courbe', (tester) async {
    await pumpApp(
      tester,
      const GrowthPage(),
      overrides: overrides(measurements),
    );
    await tester.scrollUntilVisible(
      find.text('3200 g · 52,0 cm · PC 35,0 cm'),
      200,
    );
    expect(find.text('Mesures'), findsOneWidget);
  });
}
