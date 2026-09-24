import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/dashboard/presentation/widgets/todo_section.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  final now = DateTime(2026, 9, 10, 12);
  final profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1));

  setUpAll(() => registerFallbackValue(makeEvent(startAt: DateTime(2026))));

  testWidgets(
    'un échec de sauvegarde du quick-add affiche le message d\'erreur',
    (tester) async {
      final repo = MockEventsRepository();
      when(() => repo.save(any(), any()))
          .thenAnswer((_) async => left(const NetworkFailure()));
      await pumpApp(
        tester,
        const Scaffold(body: TodoSection()),
        overrides: [
          clockProvider.overrideWithValue(FixedClock(now)),
          minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
          ),
          babyProfileProvider.overrideWith((ref) => Stream.value(profile)),
          todayEventsProvider.overrideWith((ref) => Stream.value(const [])),
          latestBottleProvider.overrideWith((ref) => Stream.value(null)),
          weekEventsProvider.overrideWith((ref) => Stream.value(const [])),
          eventsRepositoryProvider.overrideWithValue(repo),
          idGeneratorProvider.overrideWithValue(
            const FixedIdGenerator('e-new'),
          ),
          feedingPlanSyncProvider.overrideWithValue(
            const NoopFeedingPlanSync(),
          ),
        ],
      );
      await tester.tap(find.text('Soin des yeux'));
      await tester.pumpAndSettle();
      expect(
        find.text('Pas de connexion. Réessaie dans un instant.'),
        findsOneWidget,
      );
    },
  );
}
