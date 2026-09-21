import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/shared/domain/care_type.dart';

/// Brouillon d'événement daté de [now], éventuellement pré-coché.
CareEvent newEventDraft({
  required DateTime now,
  required String deviceId,
  required String id,
  CareType? preChecked,
  int? bottleMl,
}) {
  final base = CareEvent(
    id: id,
    startAt: now,
    endAt: now,
    bottleMl: bottleMl,
    createdByDeviceId: deviceId,
    createdAt: now,
    updatedAt: now,
  );
  return preChecked == null ? base : base.toggle(preChecked, true);
}
