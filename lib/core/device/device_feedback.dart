import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_feedback.g.dart';

/// Sons système joués par l'app ; muets en mode silencieux.
enum AppSound { feedingEnded, uprightEnded }

/// Retours de l'appareil : écran maintenu allumé, sons système, vibration.
abstract interface class DeviceFeedback {
  Future<void> setKeepScreenOn(bool on);

  Future<void> playSound(AppSound sound);

  Future<void> vibrate();
}

/// Pont Swift `colette/device` (voir `AppDelegate.swift`).
final class NativeDeviceFeedback implements DeviceFeedback {
  const NativeDeviceFeedback(this._channel);

  static const channelName = 'colette/device';

  final MethodChannel _channel;

  @override
  Future<void> setKeepScreenOn(bool on) => _invoke('setKeepScreenOn', on);

  @override
  Future<void> playSound(AppSound sound) => _invoke('playSound', sound.name);

  @override
  Future<void> vibrate() => HapticFeedback.mediumImpact();

  /// Un retour manqué n'empêche rien : l'échec est seulement logué.
  Future<void> _invoke(String method, Object arguments) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on Exception catch (error, stackTrace) {
      log(
        'colette/device $method a échoué',
        name: 'colette',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Retours de l'appareil ; remplacé par un faux dans les tests.
@Riverpod(keepAlive: true)
DeviceFeedback deviceFeedback(Ref ref) =>
    const NativeDeviceFeedback(MethodChannel(NativeDeviceFeedback.channelName));
