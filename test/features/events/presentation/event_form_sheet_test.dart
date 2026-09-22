import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  final now = DateTime(2026, 9, 21, 14, 30);
  late MockEventsRepository repo;

  setUpAll(() => registerFallbackValue(makeEvent(startAt: DateTime(2026))));

  setUp(() {
    repo = MockEventsRepository();
    when(() => repo.save(any(), any())).thenAnswer((_) async => right(null));
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    CareEvent? initial,
    BabyProfile? profile,
  }) => pumpApp(
    tester,
    Scaffold(body: EventFormSheet(initial: initial)),
    overrides: [
      eventsRepositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(FixedClock(now)),
      idGeneratorProvider.overrideWithValue(const FixedIdGenerator('e-new')),
      householdLocalStoreProvider.overrideWithValue(
        InMemoryHouseholdLocalStore(
          householdCode: 'ABCDEFGH',
          deviceId: 'dev-1',
        ),
      ),
      babyProfileProvider.overrideWith((ref) => Stream.value(profile)),
      feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
    ],
  );

  FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Enregistrer'),
  );

  testWidgets(
    'le bouton Enregistrer est désactivé tant que rien n\'est coché',
    (tester) async {
      await pumpSheet(tester);
      expect(saveButton(tester).onPressed, isNull);
    },
  );

  testWidgets('cocher Adrigyl puis Enregistrer sauvegarde l\'événement', (
    tester,
  ) async {
    await pumpSheet(tester);
    await tester.tap(find.text('Adrigyl'));
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.save('ABCDEFGH', captureAny())).captured.single
            as CareEvent;
    expect(saved.id, 'e-new');
    expect(saved.adrigyl, isTrue);
    expect(saved.createdByDeviceId, 'dev-1');
    expect(saved.startAt, now);
  });

  testWidgets('activer Biberon propose 120 ml par défaut', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(find.text('120 ml'), findsWidgets);
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('en édition, le titre change et l\'identifiant est conservé', (
    tester,
  ) async {
    final initial = makeEvent(
      id: 'e-existing',
      startAt: now.subtract(const Duration(hours: 2)),
      pee: true,
    );
    await pumpSheet(tester, initial: initial);
    expect(find.text('Modifier l\'événement'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.save('ABCDEFGH', captureAny())).captured.single
            as CareEvent;
    expect(saved.id, 'e-existing');
    expect(saved.createdAt, initial.createdAt);
  });

  testWidgets('la puce nombril est masquée quand le soin est désactivé', (
    tester,
  ) async {
    final profile = BabyProfile(
      name: 'Colette',
      birthDate: DateTime(2026, 9, 1),
      careSettings: const CareSettings(umbilicalCarePerDay: 0),
    );
    await pumpSheet(tester, profile: profile);
    expect(find.text('Soin du nombril'), findsNothing);
    expect(find.text('Soin des yeux'), findsOneWidget);
  });
}
