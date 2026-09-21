import 'package:colette/features/household/data/dtos/device_info_dto.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap applique les valeurs par défaut sur un document partiel', () {
    final device = DeviceInfoDto.fromMap('dev-1', const {'label': 'iPhone'});
    expect(device, const DeviceInfo(id: 'dev-1', label: 'iPhone'));
  });

  test('toMap omet fcmToken quand il est nul et l\'écrit sinon', () {
    expect(
      DeviceInfoDto.toMap(const DeviceInfo(id: 'd', label: 'x'))
          .containsKey('fcmToken'),
      isFalse,
    );
    expect(
      DeviceInfoDto.toMap(
        const DeviceInfo(id: 'd', label: 'x', fcmToken: 't'),
      )['fcmToken'],
      't',
    );
  });
}
