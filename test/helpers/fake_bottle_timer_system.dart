import 'package:colette/core/device/bottle_timer_system.dart';

/// Enregistre les appels : `sync:<fin du biberon>|<prénom>` et `clear`.
class FakeBottleTimerSystem implements BottleTimerSystem {
  final calls = <String>[];

  @override
  Future<void> sync({
    required DateTime startedAt,
    required DateTime feedingEndsAt,
    required DateTime uprightEndsAt,
    required String babyName,
  }) async => calls.add('sync:${feedingEndsAt.toIso8601String()}|$babyName');

  @override
  Future<void> clear() async => calls.add('clear');
}
