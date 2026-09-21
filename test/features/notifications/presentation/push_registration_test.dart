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
    await Future<void>.delayed(Duration.zero);
    verify(() => devices.updateFcmToken('ABCDEFGH', 'dev-1', 'tok-2'))
        .called(1);
  });

  test('sans permission, aucun token n\'est écrit', () async {
    final container = makeContainer(
      FakePushTokenSource(granted: false, token: 'tok-1'),
    );
    await container.read(pushRegistrationProvider.notifier).register();
    verifyNever(() => devices.updateFcmToken(any(), any(), any()));
  });
}
