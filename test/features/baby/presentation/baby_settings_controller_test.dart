import 'dart:async';

import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
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
    registerFallbackValue(
      GrowthMeasurement(id: 'x', measuredAt: DateTime(2026)),
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

  test('saveMeasurement refuse une mesure vide', () async {
    final ok = await controller().saveMeasurement(
      measuredAt: DateTime(2026, 9, 10),
    );
    expect(ok, isFalse);
    final error = container.read(babySettingsControllerProvider).error;
    expect(
      (error! as ValidationFailure).reason,
      ValidationReason.emptyMeasurement,
    );
    verifyNever(() => repo.saveMeasurement(any(), any()));
  });

  test('saveMeasurement crée une mesure puis synchronise le plan', () async {
    when(() => repo.saveMeasurement(any(), any()))
        .thenAnswer((_) async => right(null));
    final ok = await controller().saveMeasurement(
      measuredAt: DateTime(2026, 9, 10),
      lengthMm: 545,
      headCircumferenceMm: 370,
    );
    expect(ok, isTrue);
    final saved =
        verify(() => repo.saveMeasurement('ABCDEFGH', captureAny()))
                .captured
                .single
            as GrowthMeasurement;
    expect(
      saved,
      GrowthMeasurement(
        id: 'w-new',
        measuredAt: DateTime(2026, 9, 10),
        lengthMm: 545,
        headCircumferenceMm: 370,
      ),
    );
    verify(() => sync.sync()).called(1);
  });

  test('saveMeasurement avec un id modifie la mesure existante', () async {
    when(() => repo.saveMeasurement(any(), any()))
        .thenAnswer((_) async => right(null));
    await controller().saveMeasurement(
      id: 'm1',
      measuredAt: DateTime(2026, 9, 10),
      grams: 3600,
    );
    final saved =
        verify(() => repo.saveMeasurement('ABCDEFGH', captureAny()))
                .captured
                .single
            as GrowthMeasurement;
    expect(saved.id, 'm1');
  });

  test('deleteMeasurement supprime puis synchronise le plan', () async {
    when(() => repo.deleteMeasurement(any(), any()))
        .thenAnswer((_) async => right(null));
    expect(await controller().deleteMeasurement('m1'), isTrue);
    verify(() => repo.deleteMeasurement('ABCDEFGH', 'm1')).called(1);
    verify(() => sync.sync()).called(1);
  });

  test('setCordFallenAt désactive le soin du nombril', () async {
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    final ok = await controller().setCordFallenAt(
      profile,
      DateTime(2026, 9, 12),
    );
    expect(ok, isTrue);
    final saved =
        verify(() => repo.saveProfile('ABCDEFGH', captureAny())).captured.single
            as BabyProfile;
    expect(saved.cordFallenAt, DateTime(2026, 9, 12));
    expect(saved.careSettings.umbilicalCarePerDay, 0);
  });

  test('setCordFallenAt null remet le soin du nombril à 3', () async {
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    final disabled = profile.copyWith(
      cordFallenAt: DateTime(2026, 9, 12),
      careSettings: const CareSettings(umbilicalCarePerDay: 0),
    );
    final ok = await controller().setCordFallenAt(disabled, null);
    expect(ok, isTrue);
    final saved =
        verify(() => repo.saveProfile('ABCDEFGH', captureAny())).captured.single
            as BabyProfile;
    expect(saved.cordFallenAt, isNull);
    expect(saved.careSettings.umbilicalCarePerDay, 3);
  });

  test('updateCareSettings enregistre et synchronise', () async {
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    final ok = await controller().updateCareSettings(
      profile,
      const CareSettings(feedsPerDay: 7),
    );
    expect(ok, isTrue);
    final saved =
        verify(() => repo.saveProfile('ABCDEFGH', captureAny())).captured.single
            as BabyProfile;
    expect(saved.careSettings.feedsPerDay, 7);
    verify(() => sync.sync()).called(1);
  });

  test('la sync du plan part même si le contrôleur est détruit pendant l\'écriture', () async {
    final completer = Completer<Either<Failure, void>>();
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) => completer.future);
    final sub = container.listen(babySettingsControllerProvider, (_, _) {});
    final future = container
        .read(babySettingsControllerProvider.notifier)
        .saveProfile(profile);
    // Plus aucun écouteur : le contrôleur autoDispose est détruit pendant l'await.
    sub.close();
    await Future<void>.delayed(Duration.zero);
    completer.complete(right(null));
    expect(await future, isTrue);
    verify(() => sync.sync()).called(1);
  });
}
