import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sleep_status.freezed.dart';

/// État de sommeil actuel du bébé.
@freezed
sealed class SleepStatus with _$SleepStatus {
  /// Endormi·e depuis `session.startAt`.
  const factory SleepStatus.asleep(SleepSession session) = Asleep;

  /// Éveillé·e depuis [since] ; `null` sans aucun sommeil terminé.
  const factory SleepStatus.awake({DateTime? since}) = Awake;

  /// Sommeil en cours depuis trop longtemps : réveil probablement oublié.
  const factory SleepStatus.forgottenWake(SleepSession session) = ForgottenWake;
}

/// État actuel et total de sommeil sur les 24 dernières heures.
@freezed
abstract class SleepSummary with _$SleepSummary {
  const factory SleepSummary({
    required SleepStatus status,
    required Duration last24h,
  }) = _SleepSummary;
}
