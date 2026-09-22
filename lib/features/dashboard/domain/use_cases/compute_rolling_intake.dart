import 'package:colette/features/dashboard/domain/entities/rolling_intake.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';

/// Nombre de biberons et ml donnés dans `[now − 24 h, now]`, bornes incluses.
class ComputeRollingIntake {
  const ComputeRollingIntake();

  static const window = Duration(hours: 24);

  RollingIntake call({required List<CareEvent> events, required DateTime now}) {
    final from = now.subtract(window);
    final bottles = events.where(
      (e) =>
          e.hasBottle && !e.startAt.isBefore(from) && !e.startAt.isAfter(now),
    );
    return RollingIntake(
      bottles: bottles.length,
      ml: bottles.fold(0, (sum, e) => sum + (e.bottleMl ?? 0)),
    );
  }
}
