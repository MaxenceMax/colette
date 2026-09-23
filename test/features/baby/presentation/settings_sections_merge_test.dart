import 'dart:async';

import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/widgets/care_settings_section.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockBabyRepository extends Mock implements BabyRepository {}

void main() {
  setUpAll(
    () => registerFallbackValue(
      BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
    ),
  );

  testWidgets('une écriture de CareSettingsSection ne perd pas le changement fait '
      'juste avant par SleepSettingsSection', (tester) async {
    final repo = MockBabyRepository();
    final savedProfiles = <BabyProfile>[];
    var callCount = 0;
    final firstCallCompleter = Completer<void>();
    when(() => repo.saveProfile(any(), any())).thenAnswer((invocation) async {
      savedProfiles.add(invocation.positionalArguments[1] as BabyProfile);
      callCount++;
      if (callCount == 1) await firstCallCompleter.future;
      return right(null);
    });

    var profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1));
    late StateSetter setHarnessState;

    Widget harness() => StatefulBuilder(
      builder: (context, setState) {
        setHarnessState = setState;
        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SleepSettingsSection(profile: profile),
                CareSettingsSection(profile: profile),
              ],
            ),
          ),
        );
      },
    );

    await pumpApp(
      tester,
      harness(),
      overrides: [
        babyRepositoryProvider.overrideWithValue(repo),
        feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );

    final plusButtons = find.widgetWithIcon(IconButton, Icons.add);

    // Tape + sur "Début de la nuit" (premier stepper de SleepSettingsSection).
    await tester.tap(plusButtons.first);
    await tester.pump();

    // Simule l'écho Firestore de cette écriture pendant que le contrôleur
    // charge encore (isLoading toujours vrai).
    profile = profile.copyWith(
      careSettings: profile.careSettings.copyWith(nightStartHour: 21),
    );
    setHarnessState(() {});
    await tester.pump();

    // La première écriture se termine.
    firstCallCompleter.complete();
    await tester.pump();
    await tester.pump();

    // Tape + sur "Adrigyl par jour" (premier stepper de CareSettingsSection,
    // troisième bouton + après les deux de SleepSettingsSection).
    await tester.tap(plusButtons.at(2));
    await tester.pumpAndSettle();

    expect(savedProfiles.last.careSettings.nightStartHour, 21);
    expect(savedProfiles.last.careSettings.adrigylPerDay, 2);
  });
}
