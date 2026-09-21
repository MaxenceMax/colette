import 'package:colette/core/clock/app_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clockProvider peut être surchargé par une FixedClock', () {
    final fixed = DateTime(2026, 9, 21, 14, 30);
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(FixedClock(fixed))],
    );
    addTearDown(container.dispose);
    expect(container.read(clockProvider).now(), fixed);
  });
}
