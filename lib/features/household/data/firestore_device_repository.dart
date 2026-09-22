import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/household/data/dtos/device_info_dto.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/domain/repositories/device_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Appareils stockés dans `households/{code}/devices/{deviceId}`.
class FirestoreDeviceRepository implements DeviceRepository {
  FirestoreDeviceRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String code, String deviceId) =>
      _db
          .collection(FirestorePaths.households)
          .doc(code)
          .collection(FirestorePaths.devices)
          .doc(deviceId);

  @override
  Stream<DeviceInfo?> watchDevice(String householdCode, String deviceId) =>
      _doc(householdCode, deviceId).snapshots().map((snap) {
        final data = snap.data();
        return data == null ? null : DeviceInfoDto.fromMap(deviceId, data);
      });

  @override
  Future<Either<Failure, void>> saveDevice(
    String householdCode,
    DeviceInfo device,
  ) => guard(
    () => _doc(
      householdCode,
      device.id,
    ).set(DeviceInfoDto.toMap(device), SetOptions(merge: true)),
  );

  @override
  Future<Either<Failure, void>> updateFcmToken(
    String householdCode,
    String deviceId,
    String token,
  ) => guard(
    () => _doc(householdCode, deviceId).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)),
  );

  @override
  Future<Either<Failure, void>> deleteDevice(
    String householdCode,
    String deviceId,
  ) => guard(() => _doc(householdCode, deviceId).delete());
}
