import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_info.freezed.dart';

/// Un iPhone membre du foyer et ses préférences de notification.
@freezed
abstract class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    required String id,
    required String label,
    String? fcmToken,
    @Default(true) bool notifyOnOthersEvents,
    @Default(true) bool notifyBottleReminder,
    @Default(true) bool notifyMorningDigest,
    @Default(8) int morningDigestHour,
  }) = _DeviceInfo;
}
