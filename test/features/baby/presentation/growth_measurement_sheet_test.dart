import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/widgets/growth_measurement_sheet.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockBabyRepository extends Mock implements BabyRepository {}

void main() {
  late MockBabyRepository repo;

  setUpAll(() {
    registerFallbackValue(
      GrowthMeasurement(id: 'x', measuredAt: DateTime(2026)),
    );
  });

  setUp(() {
    repo = MockBabyRepository();
    when(() => repo.saveMeasurement(any(), any()))
        .thenAnswer((_) async => right(null));
  });

  List<Override> overrides() => [
    clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 21, 12))),
    babyProfileProvider.overrideWith(
      (ref) => Stream.value(
        BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
      ),
    ),
    babyRepositoryProvider.overrideWithValue(repo),
    feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
    idGeneratorProvider.overrideWithValue(const FixedIdGenerator('m-new')),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
  ];

  VoidCallback? saveButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed;

  testWidgets('la date va de la naissance à aujourd\'hui', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(body: GrowthMeasurementSheet()),
      overrides: overrides(),
    );
    await tester.tap(find.text('21 septembre 2026'));
    await tester.pumpAndSettle();
    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(picker.minimumDate, DateTime(2026, 9, 1));
    expect(picker.maximumDate, DateTime(2026, 9, 21, 12));
  });

  testWidgets('Enregistrer inactif tant que les trois champs sont vides', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Scaffold(body: GrowthMeasurementSheet()),
      overrides: overrides(),
    );
    expect(find.text('Ajouter une mesure'), findsOneWidget);
    expect(saveButton(tester), isNull);
    await tester.enterText(
      find.widgetWithText(TextField, 'Taille (cm)'),
      '54,5',
    );
    await tester.pump();
    expect(saveButton(tester), isNotNull);
  });

  testWidgets('enregistre taille et périmètre sans poids', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(body: GrowthMeasurementSheet()),
      overrides: overrides(),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Taille (cm)'),
      '54,5',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Périmètre crânien (cm)'),
      '37',
    );
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveMeasurement('ABCDEFGH', captureAny()))
                .captured
                .single
            as GrowthMeasurement;
    expect(
      saved,
      GrowthMeasurement(
        id: 'm-new',
        measuredAt: DateTime(2026, 9, 21),
        lengthMm: 545,
        headCircumferenceMm: 370,
      ),
    );
  });

  testWidgets('modification : champs préremplis et même identifiant', (
    tester,
  ) async {
    final initial = GrowthMeasurement(
      id: 'm1',
      measuredAt: DateTime(2026, 9, 14),
      grams: 3650,
      lengthMm: 545,
      headCircumferenceMm: 370,
    );
    await pumpApp(
      tester,
      Scaffold(body: GrowthMeasurementSheet(initial: initial)),
      overrides: overrides(),
    );
    expect(find.text('Modifier la mesure'), findsOneWidget);
    expect(find.text('14 septembre 2026'), findsOneWidget);
    expect(find.text('3650'), findsOneWidget);
    expect(find.text('54,5'), findsOneWidget);
    expect(find.text('37,0'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Périmètre crânien (cm)'),
      '',
    );
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveMeasurement('ABCDEFGH', captureAny()))
                .captured
                .single
            as GrowthMeasurement;
    expect(saved, initial.copyWith(headCircumferenceMm: null));
  });
}
