import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:colette/features/health/domain/repositories/calendar_repository.dart';
import 'package:colette/features/health/presentation/providers/calendar_sync_issue.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

void main() {
  const code = 'ABCDEFGH';
  final now = DateTime(2026, 10, 20, 12);
  late MockCalendarRepository calendar;

  Future<ProviderContainer> container(String calendarId) async {
    SharedPreferences.setMockInitialValues({
      SelectedCalendar.idKey: calendarId,
      SelectedCalendar.titleKey: 'Famille',
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: code),
        ),
        calendarRepositoryProvider.overrideWithValue(calendar),
      ],
    );
    addTearDown(c.dispose);
    await c
        .read(babyRepositoryProvider)
        .saveProfile(
          code,
          BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
        );
    return c;
  }

  void findEventsAnswers(
    String calendarId,
    Either<Failure, List<CalendarEvent>> Function() answer,
  ) => when(
    () => calendar.findEvents(
      calendarId,
      from: any(named: 'from'),
      to: any(named: 'to'),
    ),
  ).thenAnswer((_) async => answer());

  setUp(() => calendar = MockCalendarRepository());

  test(
    'accès refusé : problème signalé, puis effacé par une sync réussie',
    () async {
      final c = await container('c1');
      findEventsAnswers(
        'c1',
        () => left(const CalendarFailure(CalendarReason.accessDenied)),
      );

      await c.read(healthSyncProvider).sync();
      expect(c.read(calendarSyncIssueProvider), CalendarReason.accessDenied);

      findEventsAnswers('c1', () => right(const []));
      await c.read(healthSyncProvider).sync();
      expect(c.read(calendarSyncIssueProvider), isNull);
    },
  );

  test(
    'calendrier introuvable : l\'alerte survit à la sync suivante',
    () async {
      final c = await container('gone');
      findEventsAnswers(
        'gone',
        () => left(const CalendarFailure(CalendarReason.calendarNotFound)),
      );

      await c.read(healthSyncProvider).sync();
      expect(c.read(selectedCalendarProvider), isNull);
      expect(
        c.read(calendarSyncIssueProvider),
        CalendarReason.calendarNotFound,
      );

      await c.read(healthSyncProvider).sync();
      expect(
        c.read(calendarSyncIssueProvider),
        CalendarReason.calendarNotFound,
      );
    },
  );

  test('sans calendrier choisi : un accès refusé est oublié', () async {
    final c = await container('c1');
    c
        .read(calendarSyncIssueProvider.notifier)
        .report(CalendarReason.accessDenied);
    await c.read(selectedCalendarProvider.notifier).clear();

    await c.read(healthSyncProvider).sync();

    expect(c.read(calendarSyncIssueProvider), isNull);
  });
}
