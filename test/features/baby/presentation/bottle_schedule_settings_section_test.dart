import 'package:colette/features/baby/data/dtos/baby_profile_dto.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/widgets/bottle_schedule_settings_section.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/cupertino.dart';
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

  final plus = find.widgetWithIcon(IconButton, Icons.add);
  final minus = find.widgetWithIcon(IconButton, Icons.remove);

  Future<void> pickTime(
    WidgetTester tester,
    String current,
    DateTime value,
  ) async {
    await tester.tap(find.text(current));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
        .onDateTimeChanged(value);
    await tester.tap(find.text('Choisir'));
    await tester.pumpAndSettle();
  }

  testWidgets('affiche le nombre et un horaire par biberon', (tester) async {
    await pumpSection(tester, profile);
    expect(find.text('Biberons par jour'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('1er biberon'), findsOneWidget);
    expect(find.text('7e biberon'), findsOneWidget);
    expect(find.text('07h00'), findsOneWidget);
    expect(find.text('23h30'), findsOneWidget);
  });

  testWidgets('+ ajoute un horaire au milieu du plus grand écart', (
    tester,
  ) async {
    await pumpSection(tester, profile);
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(savedProfiles().last.careSettings.bottleTimesMinutes, [
      420,
      510,
      600,
      780,
      960,
      1140,
      1320,
      1410,
    ]);
    expect(find.text('08h30'), findsOneWidget);
    expect(find.text('8e biberon'), findsOneWidget);
  });

  testWidgets('− retire le dernier horaire', (tester) async {
    await pumpSection(tester, profile);
    await tester.tap(minus);
    await tester.pumpAndSettle();
    expect(savedProfiles().last.careSettings.bottleTimesMinutes, [
      420,
      600,
      780,
      960,
      1140,
      1320,
    ]);
    expect(find.text('23h30'), findsNothing);
  });

  testWidgets('+ désactivé à 12 biberons', (tester) async {
    await pumpSection(
      tester,
      profile.copyWith(careSettings: const CareSettings().withBottleCount(12)),
    );
    expect(tester.widget<IconButton>(plus).onPressed, isNull);
  });

  testWidgets('migration à 14 biberons : + désactivé, − retire le dernier', (
    tester,
  ) async {
    final settings = CareSettingsDto.fromMap(const {
      'firstBottleMinutes': 0,
      'lastBottleMinutes': 5000,
      'bottleIntervalMinutes': 10,
    });
    expect(settings.bottleTimesMinutes, hasLength(14));
    await pumpSection(tester, profile.copyWith(careSettings: settings));
    expect(find.text('14'), findsOneWidget);
    expect(tester.widget<IconButton>(plus).onPressed, isNull);
    await tester.tap(minus);
    await tester.pumpAndSettle();
    expect(
      savedProfiles().last.careSettings.bottleTimesMinutes,
      settings.bottleTimesMinutes.sublist(0, 13),
    );
    expect(find.text('13'), findsOneWidget);
  });

  testWidgets('un horaire choisi est enregistré et retrié', (tester) async {
    await pumpSection(tester, profile);
    await pickTime(tester, '07h00', DateTime(2000, 1, 1, 6, 30));
    expect(savedProfiles().last.careSettings.bottleTimesMinutes, [
      390,
      600,
      780,
      960,
      1140,
      1320,
      1410,
    ]);
    expect(find.text('06h30'), findsOneWidget);
  });

  testWidgets('horaire trop proche : refusé, rien n\'est écrit', (
    tester,
  ) async {
    await pumpSection(tester, profile);
    await pickTime(tester, '07h00', DateTime(2000, 1, 1, 9, 50));
    verifyNever(() => repo.saveProfile(any(), any()));
    expect(
      find.text('Deux biberons doivent être espacés d\'au moins 30 min'),
      findsOneWidget,
    );
    expect(find.text('07h00'), findsOneWidget);
  });
}
