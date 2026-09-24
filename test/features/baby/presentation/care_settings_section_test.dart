import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/widgets/care_frequency_row.dart';
import 'package:colette/features/baby/presentation/widgets/care_settings_section.dart';
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
  final profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1));

  setUpAll(() => registerFallbackValue(profile));

  late MockBabyRepository repo;

  Future<void> pumpSection(WidgetTester tester) async {
    repo = MockBabyRepository();
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: CareSettingsSection(profile: profile),
        ),
      ),
      overrides: [
        babyRepositoryProvider.overrideWithValue(repo),
        feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
  }

  List<BabyProfile> savedProfiles() =>
      verify(() => repo.saveProfile('ABCDEFGH', captureAny())).captured
          .cast<BabyProfile>();

  // Ordre des lignes : Adrigyl, yeux, nez, nombril, bain, puis le stepper biberons.
  final plusButtons = find.widgetWithIcon(IconButton, Icons.add);
  final minusButtons = find.widgetWithIcon(IconButton, Icons.remove);

  testWidgets('cinq lignes de soin avec switch, puis le stepper biberons', (
    tester,
  ) async {
    await pumpSection(tester);
    expect(find.byType(CareFrequencyRow), findsNWidgets(5));
    expect(find.byType(Switch), findsNWidgets(5));
    expect(find.text('Soin du nombril'), findsOneWidget);
    expect(find.text('Biberons par jour'), findsOneWidget);
    expect(find.text('tous les 2 jours'), findsOneWidget); // bain
  });

  testWidgets('deux taps rapides sur + s\'additionnent', (tester) async {
    await pumpSection(tester);
    await tester.tap(plusButtons.first);
    await tester.pump();
    await tester.tap(plusButtons.first);
    await tester.pumpAndSettle();
    expect(savedProfiles().last.careSettings.adrigyl.timesPerDay, 3);
    expect(
      find.descendant(
        of: find.byType(CareFrequencyRow).first,
        matching: find.text('3 fois par jour'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('− depuis 1/jour passe Adrigyl à tous les 2 jours', (
    tester,
  ) async {
    await pumpSection(tester);
    await tester.tap(minusButtons.first);
    await tester.pumpAndSettle();
    expect(
      savedProfiles().last.careSettings.adrigyl,
      const CareFrequency(everyDays: 2),
    );
    expect(find.text('tous les 2 jours'), findsNWidgets(2)); // Adrigyl + bain
  });

  testWidgets('le + du nombril sauvegarde 4 fois par jour', (tester) async {
    await pumpSection(tester);
    await tester.tap(plusButtons.at(3));
    await tester.pumpAndSettle();
    expect(savedProfiles().last.careSettings.umbilicalCare.timesPerDay, 4);
  });

  testWidgets('le switch coupe le suivi du bain, fréquence conservée', (
    tester,
  ) async {
    await pumpSection(tester);
    await tester.tap(find.byType(Switch).at(4));
    await tester.pumpAndSettle();
    expect(
      savedProfiles().last.careSettings.bath,
      const CareFrequency(everyDays: 2, enabled: false),
    );
  });
}
