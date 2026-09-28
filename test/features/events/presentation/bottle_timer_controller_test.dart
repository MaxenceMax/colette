import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/device/bottle_timer_system.dart';
import 'package:colette/core/device/device_feedback.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/use_cases/bottle_timer.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_controller.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_bottle_timer_system.dart';
import '../../../helpers/fake_device_feedback.dart';
import '../../../helpers/in_memory_bottle_timer_session_repository.dart';

class _MutableClock implements AppClock {
  _MutableClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;
}

void main() {
  final start = DateTime(2026, 9, 25, 14);
  late _MutableClock clock;
  late StreamController<DateTime> ticks;
  late FakeDeviceFeedback feedback;
  late FakeBottleTimerSystem system;
  late InMemoryBottleTimerSessionRepository sessions;
  late ProviderContainer container;

  setUp(() {
    clock = _MutableClock(start);
    ticks = StreamController<DateTime>.broadcast();
    feedback = FakeDeviceFeedback();
    system = FakeBottleTimerSystem();
    sessions = InMemoryBottleTimerSessionRepository();
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(clock),
        bottleTimerTickProvider.overrideWith((ref) => ticks.stream),
        deviceFeedbackProvider.overrideWithValue(feedback),
        bottleTimerSystemProvider.overrideWithValue(system),
        bottleTimerSessionRepositoryProvider.overrideWithValue(sessions),
        babyProfileProvider.overrideWith(
          (ref) => Stream.value(
            BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9)),
          ),
        ),
      ],
    );
    addTearDown(ticks.close);
    container
      ..listen(bottleTimerPhaseProvider, (_, _) {})
      ..listen(babyProfileProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  BottleTimerController controller() =>
      container.read(bottleTimerControllerProvider.notifier);

  /// Lit la phase (comme un rebuild) pour abonner le ticker, puis émet.
  Future<void> tick(Duration elapsed) async {
    container.read(bottleTimerPhaseProvider);
    await Future<void>.delayed(Duration.zero);
    ticks.add(start.add(elapsed));
    await Future<void>.delayed(Duration.zero);
    container.read(bottleTimerPhaseProvider);
  }

  group('contrôleur', () {
    test('au repos, pas de phase', () {
      expect(container.read(bottleTimerControllerProvider), isNull);
      expect(container.read(bottleTimerPhaseProvider), isNull);
    });

    test('start lance le minuteur avec 30 min de biberon', () {
      controller().start();
      expect(
        container.read(bottleTimerControllerProvider),
        BottleTimerRun.startingAt(start),
      );
      expect(container.read(bottleTimerPhaseProvider), isA<BottleFeeding>());
    });

    test('un tick à +30 min passe à la verticale', () async {
      controller().start();
      await tick(const Duration(minutes: 30));
      expect(container.read(bottleTimerPhaseProvider), isA<BottleUpright>());
    });

    test('skipToUpright garde le départ et termine le biberon maintenant', () {
      controller().start();
      clock.current = start.add(const Duration(minutes: 10));
      controller().skipToUpright();
      expect(
        container.read(bottleTimerControllerProvider),
        BottleTimerRun(
          startedAt: start,
          feedingEndsAt: start.add(const Duration(minutes: 10)),
        ),
      );
      expect(
        container.read(bottleTimerPhaseProvider),
        isA<BottleUpright>().having(
          (p) => p.remaining,
          'remaining',
          const Duration(minutes: 12),
        ),
      );
    });

    test('skipToUpright ne fait rien au repos', () {
      controller().skipToUpright();
      expect(container.read(bottleTimerControllerProvider), isNull);
    });

    test('reset revient au repos', () {
      controller()
        ..start()
        ..reset();
      expect(container.read(bottleTimerPhaseProvider), isNull);
    });
  });

  group('effets', () {
    setUp(() => container.listen(bottleTimerEffectsProvider, (_, _) {}));

    test('lancement : écran maintenu allumé', () {
      controller().start();
      container.read(bottleTimerPhaseProvider);
      expect(feedback.calls, ['screen:on']);
    });

    test('fin du biberon puis fin de la verticale', () async {
      controller().start();
      await tick(const Duration(minutes: 30));
      expect(feedback.calls, ['screen:on', 'sound:feedingEnded', 'vibrate']);
      await tick(const Duration(minutes: 42));
      expect(feedback.calls, [
        'screen:on',
        'sound:feedingEnded',
        'vibrate',
        'sound:uprightEnded',
        'vibrate',
        'screen:off',
      ]);
    });

    test('saut direct du biberon à la fin : seulement le son de fin', () async {
      controller().start();
      await tick(const Duration(minutes: 5));
      await tick(const Duration(minutes: 50));
      expect(feedback.calls, [
        'screen:on',
        'sound:uprightEnded',
        'vibrate',
        'screen:off',
      ]);
    });

    test('arrêt : écran relâché', () {
      controller().start();
      container.read(bottleTimerPhaseProvider);
      controller().reset();
      container.read(bottleTimerPhaseProvider);
      expect(feedback.calls, ['screen:on', 'screen:off']);
    });

    test('destruction : écran relâché', () {
      controller().start();
      container.read(bottleTimerPhaseProvider);
      container.dispose();
      expect(feedback.calls.last, 'screen:off');
    });
  });

  group('présence hors de l\'app', () {
    String syncAt(Duration feedingEnd) =>
        'sync:${start.add(feedingEnd).toIso8601String()}|Colette';

    setUp(() async {
      container.listen(bottleTimerEffectsProvider, (_, _) {});
      await container.read(babyProfileProvider.future);
    });

    test('restore remet le minuteur sans changer ses dates', () {
      final run = BottleTimerRun.startingAt(
        start.subtract(const Duration(minutes: 5)),
      );
      controller().restore(run);
      expect(container.read(bottleTimerControllerProvider), run);
    });

    test('lancement puis « Biberon terminé » : sync à chaque fois', () {
      controller().start();
      clock.current = start.add(const Duration(minutes: 10));
      controller().skipToUpright();
      expect(system.calls, [
        syncAt(const Duration(minutes: 30)),
        syncAt(const Duration(minutes: 10)),
      ]);
    });

    test('arrêt : clear et session effacée', () async {
      controller()
        ..start()
        ..reset();
      await Future<void>.delayed(Duration.zero);
      expect(system.calls.last, 'clear');
      expect(sessions.clears, 1);
    });

    test('destruction : clear et session effacée', () async {
      controller().start();
      container.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(system.calls.last, 'clear');
      expect(sessions.clears, 1);
    });
  });
}
