import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';

/// Construit un `SleepSession` de test avec des valeurs par défaut.
SleepSession makeSleep({
  String id = 's1',
  required DateTime startAt,
  DateTime? endAt,
  SleepKind kind = SleepKind.nap,
  String createdByDeviceId = 'device-test',
}) => SleepSession(
  id: id,
  startAt: startAt,
  endAt: endAt,
  kind: kind,
  createdByDeviceId: createdByDeviceId,
  createdAt: startAt,
  updatedAt: endAt ?? startAt,
);
