import 'package:colette/features/household/data/firestore_device_repository.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saveDevice puis watchDevice renvoie l\'appareil', () async {
    final repo = FirestoreDeviceRepository(FakeFirebaseFirestore());
    const device = DeviceInfo(
      id: 'dev-1',
      label: 'iPhone de Maxence',
      morningDigestHour: 7,
    );
    await repo.saveDevice('ABCDEFGH', device);
    expect(await repo.watchDevice('ABCDEFGH', 'dev-1').first, device);
  });

  test('updateFcmToken ne touche pas aux autres champs', () async {
    final repo = FirestoreDeviceRepository(FakeFirebaseFirestore());
    const device = DeviceInfo(
      id: 'dev-1',
      label: 'iPhone',
      notifyMorningDigest: false,
    );
    await repo.saveDevice('ABCDEFGH', device);
    await repo.updateFcmToken('ABCDEFGH', 'dev-1', 'token-1');
    final updated = await repo.watchDevice('ABCDEFGH', 'dev-1').first;
    expect(updated?.fcmToken, 'token-1');
    expect(updated?.notifyMorningDigest, isFalse);
  });

  test('watchDevice émet null si l\'appareil n\'existe pas', () async {
    final repo = FirestoreDeviceRepository(FakeFirebaseFirestore());
    expect(await repo.watchDevice('ABCDEFGH', 'nope').first, isNull);
  });

  test('saveDevice sans token conserve le token existant', () async {
    final repo = FirestoreDeviceRepository(FakeFirebaseFirestore());
    const device = DeviceInfo(id: 'dev-1', label: 'iPhone');
    await repo.saveDevice('ABCDEFGH', device);
    await repo.updateFcmToken('ABCDEFGH', 'dev-1', 'token-1');
    await repo.saveDevice(
      'ABCDEFGH',
      device.copyWith(label: 'iPhone de Maxence'),
    );
    final updated = await repo.watchDevice('ABCDEFGH', 'dev-1').first;
    expect(updated?.fcmToken, 'token-1');
    expect(updated?.label, 'iPhone de Maxence');
  });

  test('deleteDevice retire le document', () async {
    final repo = FirestoreDeviceRepository(FakeFirebaseFirestore());
    const device = DeviceInfo(id: 'dev-1', label: 'iPhone');
    await repo.saveDevice('ABCDEFGH', device);
    final result = await repo.deleteDevice('ABCDEFGH', 'dev-1');
    expect(result.isRight(), isTrue);
    expect(await repo.watchDevice('ABCDEFGH', 'dev-1').first, isNull);
  });

  test(
    'deleteDevice sans document existant renvoie quand même right',
    () async {
      final repo = FirestoreDeviceRepository(FakeFirebaseFirestore());
      final result = await repo.deleteDevice('ABCDEFGH', 'nope');
      expect(result.isRight(), isTrue);
    },
  );
}
