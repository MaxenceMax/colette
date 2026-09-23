import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_calendar.freezed.dart';

/// Calendrier modifiable de cet iPhone ; [source] : compte (iCloud, Gmail…).
@freezed
abstract class DeviceCalendar with _$DeviceCalendar {
  const factory DeviceCalendar({
    required String id,
    required String title,
    String? colorHex,
    required String source,
  }) = _DeviceCalendar;
}
