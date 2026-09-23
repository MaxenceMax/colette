import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:colette/features/health/domain/repositories/medical_repository.dart';
import 'package:colette/features/health/presentation/providers/custom_appointment_controller.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
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

  setUpAll(() => registerFallbackValue(makeAppointment()));

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

  CustomAppointmentController controller() =>
      container.read(customAppointmentControllerProvider.notifier);

  test('enregistre le RDV nettoyé et horodaté, puis synchronise', () async {
    when(() => repo.saveAppointment(any(), any()))
        .thenAnswer((_) async => right(null));
    final ok = await controller().save(
      makeAppointment(title: ' ORL ', appointmentAt: DateTime(2026, 12, 1, 9)),
      birthDate: birth,
    );
    expect(ok, isTrue);
    final saved =
        verify(() => repo.saveAppointment('ABCDEFGH', captureAny()))
                .captured
                .single
            as CustomAppointment;
    expect(saved.title, 'ORL');
    expect(saved.updatedAt, now);
    expect(saved.updatedByDeviceId, 'device-b');
    verify(() => sync.sync()).called(1);
  });

  test('refuse un RDV invalide sans écrire ni synchroniser', () async {
    final sub = container.listen(
      customAppointmentControllerProvider,
      (_, _) {},
    );
    addTearDown(sub.close);
    final ok = await controller().save(
      makeAppointment(title: ''),
      birthDate: birth,
    );
    expect(ok, isFalse);
    expect(
      (container.read(customAppointmentControllerProvider).error!
              as ValidationFailure)
          .reason,
      ValidationReason.medicalTitleRequired,
    );
    verifyNever(() => repo.saveAppointment(any(), any()));
    verifyNever(() => sync.sync());
  });

  test('supprime puis synchronise', () async {
    when(() => repo.deleteAppointment(any(), any()))
        .thenAnswer((_) async => right(null));
    expect(await controller().delete('rdv-1'), isTrue);
    verify(() => repo.deleteAppointment('ABCDEFGH', 'rdv-1')).called(1);
    verify(() => sync.sync()).called(1);
  });

  test('échec réseau : état en erreur, pas de sync', () async {
    when(() => repo.deleteAppointment(any(), any()))
        .thenAnswer((_) async => left(const NetworkFailure()));
    final sub = container.listen(
      customAppointmentControllerProvider,
      (_, _) {},
    );
    addTearDown(sub.close);
    expect(await controller().delete('rdv-1'), isFalse);
    expect(
      container.read(customAppointmentControllerProvider).error,
      isA<NetworkFailure>(),
    );
    verifyNever(() => sync.sync());
  });
}
