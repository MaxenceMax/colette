import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';

/// Conversion `DeviceInfo` ↔ document Firestore `devices/{id}`.
abstract final class DeviceInfoDto {
  /// Omet `fcmToken` quand il est nul : seul `updateFcmToken` gère le token.
  static Map<String, dynamic> toMap(DeviceInfo device) => {
    'label': device.label,
    'fcmToken': ?device.fcmToken,
    'notifyOnOthersEvents': device.notifyOnOthersEvents,
    'notifyBottleReminder': device.notifyBottleReminder,
    'notifyMorningDigest': device.notifyMorningDigest,
    'morningDigestHour': device.morningDigestHour,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static DeviceInfo fromMap(String id, Map<String, dynamic> map) => DeviceInfo(
    id: id,
    label: map['label'] as String? ?? '',
    fcmToken: map['fcmToken'] as String?,
    notifyOnOthersEvents: map['notifyOnOthersEvents'] as bool? ?? true,
    notifyBottleReminder: map['notifyBottleReminder'] as bool? ?? true,
    notifyMorningDigest: map['notifyMorningDigest'] as bool? ?? true,
    morningDigestHour: (map['morningDigestHour'] as num?)?.toInt() ?? 8,
  );
}
