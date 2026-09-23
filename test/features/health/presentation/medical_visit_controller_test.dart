import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/repositories/medical_repository.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/medical_visit_controller.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../health_factories.dart';

class MockMedicalRepository extends Mock implements MedicalRepository {}

class MockHealthSync extends Mock implements HealthSync {}

void main() {
  late MockMedicalRepository repo;
  late MockHealthSync sync;
  late ProviderContainer container;
  final birth = DateTime(2026, 9, 1);
  final now = DateTime(2026, 11, 10, 12);

  setUpAll(() {
    registerFallbackValue(makeVisit(MedicalStageId.day8));
    registerFallbackValue(MedicalStageId.day8);
  });

  setUp(() {
    repo = MockMedicalRepository();
    sync = MockHealthSync();
    when(() => sync.sync()).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        medicalRepositoryProvider.overrideWithValue(repo),
        healthSyncProvider.overrideWithValue(sync),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(
            householdCode: 'ABCDEFGH',
            deviceId: 'device-b',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  MedicalVisitController controller() =>
      container.read(medicalVisitControllerProvider.notifier);

  test(
    'enregistre la visite horodatée par cet iPhone puis synchronise',
    () async {
      when(() => repo.saveVisit(any(), any()))
          .thenAnswer((_) async => right(null));
      final ok = await controller().save(
        makeVisit(MedicalStageId.m2, appointmentAt: DateTime(2026, 12, 1, 9)),
        birthDate: birth,
      );
      expect(ok, isTrue);
      final saved =
          verify(() => repo.saveVisit('ABCDEFGH', captureAny())).captured.single
              as MedicalVisit;
      expect(saved.updatedAt, now);
      expect(saved.updatedByDeviceId, 'device-b');
      verify(() => sync.sync()).called(1);
    },
  );

  test('une visite vide est supprimée', () async {
    when(() => repo.deleteVisit(any(), any()))
        .thenAnswer((_) async => right(null));
    expect(
      await controller().save(makeVisit(MedicalStageId.m2), birthDate: birth),
      isTrue,
    );
    verify(() => repo.deleteVisit('ABCDEFGH', MedicalStageId.m2)).called(1);
  });

  test('refuse une visite invalide sans écrire ni synchroniser', () async {
    final sub = container.listen(medicalVisitControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final ok = await controller().save(
      makeVisit(MedicalStageId.m2, doneAt: DateTime(2026, 12, 1)),
      birthDate: birth,
    );
    expect(ok, isFalse);
    expect(
      (container.read(medicalVisitControllerProvider).error!
              as ValidationFailure)
          .reason,
      ValidationReason.medicalDateInFuture,
    );
    verifyNever(() => repo.saveVisit(any(), any()));
    verifyNever(() => sync.sync());
  });

  test(
    'la sync part même si le contrôleur est détruit pendant l\'écriture',
    () async {
      final completer = Completer<Either<Failure, void>>();
      when(() => repo.saveVisit(any(), any()))
          .thenAnswer((_) => completer.future);
      final sub = container.listen(medicalVisitControllerProvider, (_, _) {});
      final future = controller().save(
        makeVisit(MedicalStageId.m2, note: 'x'),
        birthDate: birth,
      );
      sub.close();
      await Future<void>.delayed(Duration.zero);
      completer.complete(right(null));
      expect(await future, isTrue);
      verify(() => sync.sync()).called(1);
    },
  );
}
