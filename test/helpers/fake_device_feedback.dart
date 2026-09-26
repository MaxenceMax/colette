import 'package:colette/core/device/device_feedback.dart';

/// Enregistre les appels (`screen:on`, `screen:off`, `sound:<nom>`, `vibrate`).
class FakeDeviceFeedback implements DeviceFeedback {
  final calls = <String>[];

  @override
  Future<void> setKeepScreenOn(bool on) async =>
      calls.add(on ? 'screen:on' : 'screen:off');

  @override
  Future<void> playSound(AppSound sound) async =>
      calls.add('sound:${sound.name}');

  @override
  Future<void> vibrate() async => calls.add('vibrate');
}
