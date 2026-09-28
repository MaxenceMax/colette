import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bottle_timer_system.g.dart';

/// Présence du minuteur de biberon hors de l'app : Live Activity (iOS 16.1+)
/// et notifications locales de fin de phase.
abstract interface class BottleTimerSystem {
  /// Crée ou met à jour l'activité et reprogramme les notifications.
  Future<void> sync({
    required DateTime startedAt,
    required DateTime feedingEndsAt,
    required DateTime uprightEndsAt,
    required String babyName,
  });

  /// Termine l'activité et retire les notifications.
  Future<void> clear();
}

/// Pont Swift `colette/bottle-timer` (voir `BottleTimerChannel.swift`).
final class NativeBottleTimerSystem implements BottleTimerSystem {
  const NativeBottleTimerSystem(this._channel);

  static const channelName = 'colette/bottle-timer';

  final MethodChannel _channel;

  @override
  Future<void> sync({
    required DateTime startedAt,
    required DateTime feedingEndsAt,
    required DateTime uprightEndsAt,
    required String babyName,
  }) => _invoke('sync', {
    'startedAt': startedAt.millisecondsSinceEpoch,
    'feedingEndsAt': feedingEndsAt.millisecondsSinceEpoch,
    'uprightEndsAt': uprightEndsAt.millisecondsSinceEpoch,
    'babyName': babyName,
  });

  @override
  Future<void> clear() => _invoke('clear', null);

  /// L'affichage hors de l'app est un bonus : l'échec est seulement logué.
  Future<void> _invoke(String method, Object? arguments) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on Exception catch (error, stackTrace) {
      log(
        'colette/bottle-timer $method a échoué',
        name: 'colette',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Pont du minuteur hors de l'app ; remplacé par un faux dans les tests.
@Riverpod(keepAlive: true)
BottleTimerSystem bottleTimerSystem(Ref ref) => const NativeBottleTimerSystem(
  MethodChannel(NativeBottleTimerSystem.channelName),
);
