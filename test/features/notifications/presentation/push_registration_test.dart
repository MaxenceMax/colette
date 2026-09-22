import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/domain/repositories/device_repository.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_push_token_source.dart';
import '../../../helpers/in_memory_household_local_store.dart';

class MockDeviceRepository extends Mock implements DeviceRepository {}

void main() {
  late MockDeviceRepository devices;

  ProviderContainer makeContainer(FakePushTokenSource source) {
    final container = ProviderContainer(
      overrides: [
        pushTokenSourceProvider.overrideWithValue(source),
        deviceRepositoryProvider.overrideWithValue(devices),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(
            householdCode: 'ABCDEFGH',
            deviceId: 'dev-1',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    devices = MockDeviceRepository();
    when(() => devices.updateFcmToken(any(), any(), any()))
        .thenAnswer((_) async => right(null));
  });

  test('register écrit le token puis suit les renouvellements', () async {
    final source = FakePushTokenSource(granted: true, token: 'tok-1');
    final container = makeContainer(source);
    await container.read(pushRegistrationProvider.notifier).register();
    verify(() => devices.updateFcmToken('ABCDEFGH', 'dev-1', 'tok-1'))
        .called(1);

    source.emitRefresh('tok-2');
    await pumpEventQueue();
    verify(() => devices.updateFcmToken('ABCDEFGH', 'dev-1', 'tok-2'))
        .called(1);
  });

  test(
    'deux register() concurrents partagent un seul enregistrement',
    () async {
      final source = FakePushTokenSource(granted: true, token: 'tok-1');
      final container = makeContainer(source);
      final notifier = container.read(pushRegistrationProvider.notifier);
      await Future.wait([notifier.register(), notifier.register()]);
      verify(() => devices.updateFcmToken('ABCDEFGH', 'dev-1', 'tok-1'))
          .called(1);

      source.emitRefresh('tok-2');
      await pumpEventQueue();
      verify(() => devices.updateFcmToken('ABCDEFGH', 'dev-1', 'tok-2'))
          .called(1);
    },
  );

  test(
    'un renouvellement après changement de foyer écrit dans le nouveau foyer',
    () async {
      final source = FakePushTokenSource(granted: true, token: 'tok-1');
      final container = makeContainer(source);
      await container.read(pushRegistrationProvider.notifier).register();
      verify(() => devices.updateFcmToken('ABCDEFGH', 'dev-1', 'tok-1'))
          .called(1);

      await container.read(currentHouseholdCodeProvider.notifier).clear();
      await container
          .read(currentHouseholdCodeProvider.notifier)
          .set('IJKLMNOP');

      source.emitRefresh('tok-2');
      await pumpEventQueue();
      verify(() => devices.updateFcmToken('IJKLMNOP', 'dev-1', 'tok-2'))
          .called(1);
      verifyNever(() => devices.updateFcmToken('ABCDEFGH', 'dev-1', 'tok-2'));
    },
  );

  test('une exception du plugin met le provider en erreur', () async {
    final source = FakePushTokenSource(
      granted: true,
      permissionError: Exception('apns'),
    );
    final container = makeContainer(source);
    await container.read(pushRegistrationProvider.notifier).register();
    final state = container.read(pushRegistrationProvider);
    expect(state, isA<AsyncError<void>>());
    expect((state as AsyncError<void>).error, isA<UnknownFailure>());
    verifyNever(() => devices.updateFcmToken(any(), any(), any()));
  });

  test('permission refusée → ValidationFailure(notificationsDenied)', () async {
    final container = makeContainer(FakePushTokenSource(granted: false));
    await container.read(pushRegistrationProvider.notifier).register();
    final state = container.read(pushRegistrationProvider);
    expect(state, isA<AsyncError<void>>());
    expect(
      (state as AsyncError<void>).error,
      const ValidationFailure(ValidationReason.notificationsDenied),
    );
    verifyNever(() => devices.updateFcmToken(any(), any(), any()));
  });
}
