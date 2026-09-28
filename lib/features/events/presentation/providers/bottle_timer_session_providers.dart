import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/events/data/repositories/prefs_bottle_timer_session_repository.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/domain/repositories/bottle_timer_session_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bottle_timer_session_providers.g.dart';

/// Stockage local de la session du minuteur ; remplacé en test.
@Riverpod(keepAlive: true)
BottleTimerSessionRepository bottleTimerSessionRepository(Ref ref) =>
    PrefsBottleTimerSessionRepository(ref.watch(sharedPreferencesProvider));

/// Session interrompue à rouvrir sur Aujourd'hui, posée au démarrage par
/// `BottleTimerResumeGate` et consommée par `DashboardPage`.
@Riverpod(keepAlive: true)
class BottleTimerResume extends _$BottleTimerResume {
  @override
  BottleTimerSession? build() => null;

  void offer(BottleTimerSession session) => state = session;

  /// Renvoie la session proposée et l'efface.
  BottleTimerSession? take() {
    final session = state;
    state = null;
    return session;
  }
}
