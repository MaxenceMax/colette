import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/widgets/bottle_schedule_settings_section.dart';
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

  Future<void> pumpSection(WidgetTester tester, BabyProfile profile) async {
    repo = MockBabyRepository();
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: BottleScheduleSettingsSection(profile: profile),
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

  // Ordre des lignes : premier biberon, biberon du soir, intervalle.
  final plusButtons = find.widgetWithIcon(IconButton, Icons.add);
  final minusButtons = find.widgetWithIcon(IconButton, Icons.remove);

  testWidgets('affiche les horaires par défaut et le nombre déduit', (
    tester,
  ) async {
    await pumpSection(tester, profile);
    expect(find.text('Premier biberon'), findsOneWidget);
    expect(find.text('Biberon du soir'), findsOneWidget);
    expect(find.text('Intervalle'), findsOneWidget);
    expect(find.text('7 h 00'), findsOneWidget);
    expect(find.text('23 h 30'), findsOneWidget);
    expect(find.text('3 h 00'), findsOneWidget);
    expect(find.text('≈ 7 biberons par jour'), findsOneWidget);
  });

  testWidgets('− du premier biberon enregistre 6 h 45', (tester) async {
    await pumpSection(tester, profile);
    await tester.tap(minusButtons.first);
    await tester.pumpAndSettle();
    expect(savedProfiles().last.careSettings.firstBottleMinutes, 405);
    expect(find.text('6 h 45'), findsOneWidget);
  });

  testWidgets('deux + sur l\'intervalle : 3 h 30 et 6 biberons', (
    tester,
  ) async {
    await pumpSection(tester, profile);
    await tester.tap(plusButtons.at(2));
    await tester.pump();
    await tester.tap(plusButtons.at(2));
    await tester.pumpAndSettle();
    expect(savedProfiles().last.careSettings.bottleIntervalMinutes, 210);
    expect(find.text('3 h 30'), findsOneWidget);
    expect(find.text('≈ 6 biberons par jour'), findsOneWidget);
  });

  testWidgets('le + du soir est désactivé à 23 h 45', (tester) async {
    await pumpSection(
      tester,
      profile.copyWith(
        careSettings: const CareSettings(
          lastBottleMinutes: CareSettings.maxLastBottleMinutes,
        ),
      ),
    );
    expect(find.text('23 h 45'), findsOneWidget);
    expect(tester.widget<IconButton>(plusButtons.at(1)).onPressed, isNull);
    expect(tester.widget<IconButton>(minusButtons.at(1)).onPressed, isNotNull);
  });
}
