import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bottle_timer_session.freezed.dart';

/// Au-delà, un minuteur interrompu n'est plus repris.
const bottleTimerSessionExpiry = Duration(hours: 12);

/// Minuteur de biberon en cours et brouillon du soin, persistés pour
/// reprendre après une app tuée.
@freezed
abstract class BottleTimerSession with _$BottleTimerSession {
  const BottleTimerSession._();

  const factory BottleTimerSession({
    required BottleTimerRun run,
    required CareEvent draft,

    /// Minuteur lancé depuis l'édition d'un soin existant.
    required bool editing,
  }) = _BottleTimerSession;

  /// `true` si le minuteur a été lancé il y a plus de 12 h.
  bool isExpiredAt(DateTime now) =>
      now.difference(run.startedAt) > bottleTimerSessionExpiry;
}
