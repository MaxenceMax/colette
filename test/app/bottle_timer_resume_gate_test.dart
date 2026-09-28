import 'package:colette/app/colette_app.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_controller.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_session_providers.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_event_factory.dart';
import '../helpers/colette_app_overrides.dart';
import '../helpers/fake_bottle_timer_system.dart';
import '../helpers/in_memory_bottle_timer_session_repository.dart';

void main() {
  final now = DateTime(2026, 9, 28, 3);

  Future<void> pumpColetteApp(
    WidgetTester tester, {
    required InMemoryBottleTimerSessionRepository sessions,
    required FakeBottleTimerSystem system,
    String? code = 'ABCDEFGH',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...await coletteAppOverrides(
            householdCode: code,
            deviceId: 'dev-1',
            bottleTimerSystem: system,
          ),
          bottleTimerSessionRepositoryProvider.overrideWithValue(sessions),
          clockProvider.overrideWithValue(FixedClock(now)),
          bottleTimerTickProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const ColetteApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  BottleTimerSession sessionStartedAgo(Duration ago) {
    final run = BottleTimerRun.startingAt(now.subtract(ago));
    return BottleTimerSession(
      run: run,
      draft: makeEvent(startAt: run.startedAt, bottleMl: 90),
      editing: false,
    );
  }

  testWidgets('sans session : activité orpheline fermée, pas de formulaire', (
    tester,
  ) async {
    final system = FakeBottleTimerSystem();
    await pumpColetteApp(
      tester,
      sessions: InMemoryBottleTimerSessionRepository(),
      system: system,
    );
    expect(system.calls, ['clear']);
    expect(find.byType(EventFormSheet), findsNothing);
  });

  testWidgets('session en cours : formulaire rouvert', (tester) async {
    final system = FakeBottleTimerSystem();
    await pumpColetteApp(
      tester,
      sessions: InMemoryBottleTimerSessionRepository(
        session: sessionStartedAgo(const Duration(minutes: 10)),
      ),
      system: system,
    );
    expect(find.byType(EventFormSheet), findsOneWidget);
    expect(system.calls.single, startsWith('sync:'));
  });

  testWidgets('session expirée : effacée, pas de formulaire', (tester) async {
    final sessions = InMemoryBottleTimerSessionRepository(
      session: sessionStartedAgo(const Duration(hours: 13)),
    );
    await pumpColetteApp(
      tester,
      sessions: sessions,
      system: FakeBottleTimerSystem(),
    );
    expect(sessions.session, isNull);
    expect(find.byType(EventFormSheet), findsNothing);
  });

  testWidgets('sans foyer : rien n\'est repris', (tester) async {
    final sessions = InMemoryBottleTimerSessionRepository(
      session: sessionStartedAgo(const Duration(minutes: 10)),
    );
    await pumpColetteApp(
      tester,
      sessions: sessions,
      system: FakeBottleTimerSystem(),
      code: null,
    );
    expect(find.byType(EventFormSheet), findsNothing);
    expect(sessions.session, isNotNull);
  });
}
