import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/widgets/growth_measurement_sheet.dart';
import 'package:colette/features/baby/presentation/widgets/measurements_section.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockBabyRepository extends Mock implements BabyRepository {}

void main() {
  final measurements = [
    GrowthMeasurement(
      id: 'm2',
      measuredAt: DateTime(2026, 9, 14),
      grams: 3650,
      lengthMm: 545,
      headCircumferenceMm: 370,
    ),
    GrowthMeasurement(id: 'm1', measuredAt: DateTime(2026, 9, 2), grams: 3200),
  ];

  Future<MockBabyRepository> pump(
    WidgetTester tester,
    List<GrowthMeasurement> list,
  ) async {
    final repo = MockBabyRepository();
    when(() => repo.deleteMeasurement(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      const Scaffold(body: SingleChildScrollView(child: MeasurementsSection())),
      overrides: [
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 21, 12))),
        babyProfileProvider.overrideWith(
          (ref) => Stream.value(
            BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
          ),
        ),
        measurementsProvider.overrideWith((ref) => Stream.value(list)),
        babyRepositoryProvider.overrideWithValue(repo),
        feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    return repo;
  }

  testWidgets('sans mesure : message et bouton d\'ajout', (tester) async {
    await pump(tester, const []);
    expect(
      find.text('Aucune mesure. Ajoute un poids pour un calcul au poids.'),
      findsOneWidget,
    );
    expect(find.text('Ajouter une mesure'), findsOneWidget);
  });

  testWidgets('une ligne par mesure avec ses valeurs et sa date', (
    tester,
  ) async {
    await pump(tester, measurements);
    expect(find.text('3650 g · 54,5 cm · PC 37,0 cm'), findsOneWidget);
    expect(find.text('14 sept. 2026'), findsOneWidget);
    expect(find.text('3200 g'), findsOneWidget);
  });

  testWidgets('toucher une ligne ouvre la feuille en modification', (
    tester,
  ) async {
    await pump(tester, measurements);
    await tester.tap(find.text('3650 g · 54,5 cm · PC 37,0 cm'));
    await tester.pumpAndSettle();
    expect(find.byType(GrowthMeasurementSheet), findsOneWidget);
    expect(find.text('Modifier la mesure'), findsOneWidget);
  });

  testWidgets('la poubelle supprime la mesure', (tester) async {
    final repo = await pump(tester, measurements);
    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();
    verify(() => repo.deleteMeasurement('ABCDEFGH', 'm1')).called(1);
  });
}
