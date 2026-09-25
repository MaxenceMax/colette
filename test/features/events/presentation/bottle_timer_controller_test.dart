import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/events/domain/use_cases/bottle_timer.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 9, 25, 14);
  late StreamController<DateTime> ticks;
  late ProviderContainer container;

  setUp(() {
    ticks = StreamController<DateTime>.broadcast();
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(FixedClock(start)),
        bottleTimerTickProvider.overrideWith((ref) => ticks.stream),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(ticks.close);
    container.listen(bottleTimerPhaseProvider, (_, _) {});
  });

  test('au repos, pas de phase', () {
    expect(container.read(bottleTimerControllerProvider), isNull);
    expect(container.read(bottleTimerPhaseProvider), isNull);
  });

  test('start prend l\'heure de l\'horloge et démarre la phase biberon', () {
    container.read(bottleTimerControllerProvider.notifier).start();
    expect(container.read(bottleTimerControllerProvider), start);
    expect(container.read(bottleTimerPhaseProvider), isA<BottleFeeding>());
  });

  test('un tick à +30 min passe à la verticale', () async {
    container.read(bottleTimerControllerProvider.notifier).start();
    container.read(bottleTimerPhaseProvider);
    ticks.add(start.add(const Duration(minutes: 30)));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(bottleTimerPhaseProvider), isA<BottleUpright>());
  });

  test('reset revient au repos', () {
    container.read(bottleTimerControllerProvider.notifier)
      ..start()
      ..reset();
    expect(container.read(bottleTimerPhaseProvider), isNull);
  });
}
