import 'package:colette/features/sleep/domain/entities/sleep_session.dart';

/// Écritures du réveil : le sommeil à fermer et les doublons à supprimer.
typedef WakeUpPlan = ({SleepSession close, List<String> deleteIds});

/// Ferme le plus ancien des sommeils ouverts [open] à [now] ; les autres sont
/// des doublons (deux appuis simultanés) à supprimer. `null` si aucun.
WakeUpPlan? planWakeUp(List<SleepSession> open, DateTime now) {
  if (open.isEmpty) return null;
  final sorted = [...open]..sort((a, b) => a.startAt.compareTo(b.startAt));
  return (
    close: sorted.first.copyWith(endAt: now, updatedAt: now),
    deleteIds: [for (final s in sorted.skip(1)) s.id],
  );
}
