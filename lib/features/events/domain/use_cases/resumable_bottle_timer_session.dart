import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/domain/repositories/bottle_timer_session_repository.dart';

/// Session à reprendre au démarrage ; efface une session expirée ou illisible.
Future<BottleTimerSession?> resumableBottleTimerSession({
  required BottleTimerSessionRepository repository,
  required DateTime now,
}) async {
  final loaded = await repository.load();
  final session = loaded.getOrElse((_) => null);
  if (session != null && !session.isExpiredAt(now)) return session;
  if (loaded.isLeft() || session != null) await repository.clear();
  return null;
}
