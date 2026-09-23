import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sleep_session.freezed.dart';

/// Une période de sommeil ; `endAt` vaut `null` tant qu'elle est en cours.
@freezed
abstract class SleepSession with _$SleepSession {
  const SleepSession._();

  const factory SleepSession({
    required String id,
    required DateTime startAt,
    DateTime? endAt,
    required SleepKind kind,
    required String createdByDeviceId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SleepSession;

  bool get isOngoing => endAt == null;

  /// Fin effective : `endAt`, ou [now] si le sommeil est en cours.
  DateTime endOr(DateTime now) => endAt ?? now;

  /// Durée complète, arrêtée à [now] si le sommeil est en cours.
  Duration durationUntil(DateTime now) => endOr(now).difference(startAt);
}
