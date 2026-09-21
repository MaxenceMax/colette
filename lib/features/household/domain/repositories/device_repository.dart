import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:fpdart/fpdart.dart';

/// Appareils membres d'un foyer.
abstract interface class DeviceRepository {
  Stream<DeviceInfo?> watchDevice(String householdCode, String deviceId);

  Future<Either<Failure, void>> saveDevice(
    String householdCode,
    DeviceInfo device,
  );

  Future<Either<Failure, void>> updateFcmToken(
    String householdCode,
    String deviceId,
    String token,
  );
}
