import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/widgets/care_settings_section.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
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

  testWidgets('deux taps rapides sur un stepper s\'additionnent', (
    tester,
  ) async {
    final repo = MockBabyRepository();
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
    final plusButtons = find.widgetWithIcon(IconButton, Icons.add);
    await tester.tap(plusButtons.first);
    await tester.pump();
    await tester.tap(plusButtons.first);
    await tester.pumpAndSettle();
    final saved = verify(() => repo.saveProfile('ABCDEFGH', captureAny()))
        .captured
        .cast<BabyProfile>();
    expect(saved.last.careSettings.adrigylPerDay, 3);
    expect(
      find.descendant(
        of: find.byType(IntStepperRow).first,
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('le stepper nombril sauvegarde le nombre de soins par jour', (
    tester,
  ) async {
    final repo = MockBabyRepository();
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
    expect(find.text('Soin du nombril par jour'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    // Ordre des steppers : Adrigyl, yeux, nez, nombril, bain, biberons.
    final plusButtons = find.widgetWithIcon(IconButton, Icons.add);
    await tester.tap(plusButtons.at(3));
    await tester.pumpAndSettle();
    final saved = verify(() => repo.saveProfile('ABCDEFGH', captureAny()))
        .captured
        .cast<BabyProfile>();
    expect(saved.last.careSettings.umbilicalCarePerDay, 4);
  });
}
