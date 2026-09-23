import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/pages/weight_curve_page.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/widgets/add_weight_sheet.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final weights = [
    WeightEntry(id: 'a', measuredAt: DateTime(2026, 9, 2), grams: 3200),
    WeightEntry(id: 'c', measuredAt: DateTime(2026, 9, 14), grams: 3650),
    WeightEntry(id: 'b', measuredAt: DateTime(2026, 9, 10), grams: 3470),
  ];

  List<Override> overrides(List<WeightEntry> list) => [
    clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 15, 12))),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
    weightsProvider.overrideWith((ref) => Stream.value(list)),
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
}
