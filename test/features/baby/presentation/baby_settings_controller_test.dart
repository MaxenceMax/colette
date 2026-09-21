import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockBabyRepository extends Mock implements BabyRepository {}

class MockFeedingPlanSync extends Mock implements FeedingPlanSync {}

void main() {
  late MockBabyRepository repo;
  late MockFeedingPlanSync sync;
  late ProviderContainer container;
  final profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1));

  setUpAll(() {
    registerFallbackValue(profile);
    registerFallbackValue(
      WeightEntry(id: 'x', measuredAt: DateTime(2026), grams: 3000),
    );
  });

  setUp(() {
    repo = MockBabyRepository();
    sync = MockFeedingPlanSync();
    when(() => sync.sync()).thenAnswer((_) async {});
    when(() => repo.watchProfile(any()))
        .thenAnswer((_) => Stream.value(profile));
    container = ProviderContainer(
      overrides: [
        babyRepositoryProvider.overrideWithValue(repo),
        feedingPlanSyncProvider.overrideWithValue(sync),
        idGeneratorProvider.overrideWithValue(const FixedIdGenerator('w-new')),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  BabySettingsController controller() =>
      container.read(babySettingsControllerProvider.notifier);

  test('addWeight refuse un poids hors bornes', () async {
    final ok = await controller().addWeight(
      measuredAt: DateTime(2026, 9, 10),
      grams: 500,
    );
    expect(ok, isFalse);
    expect(
      container.read(babySettingsControllerProvider).error,
      isA<ValidationFailure>(),
    );
    verifyNever(() => repo.addWeight(any(), any()));
  });

  test('addWeight enregistre puis synchronise le plan', () async {
    when(() => repo.addWeight(any(), any()))
        .thenAnswer((_) async => right(null));
    final ok = await controller().addWeight(
      measuredAt: DateTime(2026, 9, 10),
      grams: 3600,
    );
    expect(ok, isTrue);
    final saved =
        verify(() => repo.addWeight('ABCDEFGH', captureAny())).captured.single
            as WeightEntry;
    expect(saved.id, 'w-new');
    expect(saved.grams, 3600);
    verify(() => sync.sync()).called(1);
  });

  test('setCordFallenAt désactive le soin du nombril', () async {
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    // Garde le provider vivant : sans écoute persistante, `container.read`
    // referme aussitôt sa souscription temporaire et l'autoDispose détruit
    // le provider avant que le flux n'émette (« disposed during loading »).
    container.listen(babyProfileProvider, (_, _) {});
    await container.read(babyProfileProvider.future);
    final ok = await controller().setCordFallenAt(DateTime(2026, 9, 12));
    expect(ok, isTrue);
    final saved =
        verify(() => repo.saveProfile('ABCDEFGH', captureAny())).captured.single
            as BabyProfile;
    expect(saved.cordFallenAt, DateTime(2026, 9, 12));
    expect(saved.careSettings.umbilicalCareEnabled, isFalse);
  });

  test('updateCareSettings enregistre et synchronise', () async {
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    // Voir la note dans le test précédent : évite l'autoDispose prématuré.
    container.listen(babyProfileProvider, (_, _) {});
    await container.read(babyProfileProvider.future);
    final ok = await controller().updateCareSettings(
      const CareSettings(feedsPerDay: 7),
    );
    expect(ok, isTrue);
    final saved =
        verify(() => repo.saveProfile('ABCDEFGH', captureAny())).captured.single
            as BabyProfile;
    expect(saved.careSettings.feedsPerDay, 7);
    verify(() => sync.sync()).called(1);
  });
}
