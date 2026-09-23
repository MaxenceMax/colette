import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/calendar_choice.dart';
import 'package:colette/features/health/domain/entities/device_calendar.dart';
import 'package:colette/features/health/domain/repositories/calendar_repository.dart';
import 'package:colette/features/health/presentation/providers/calendar_settings_controller.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

class MockHealthSync extends Mock implements HealthSync {}

void main() {
  late MockCalendarRepository calendar;
  late MockHealthSync sync;
  late ProviderContainer container;

  setUp(() async {
    calendar = MockCalendarRepository();
    sync = MockHealthSync();
    when(() => sync.sync()).thenAnswer((_) async {});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        calendarRepositoryProvider.overrideWithValue(calendar),
        healthSyncProvider.overrideWithValue(sync),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
  });

  CalendarSettingsController controller() =>
      container.read(calendarSettingsControllerProvider.notifier);

  test('accès refusé donne AsyncError sans lister les calendriers', () async {
    when(() => calendar.requestAccess()).thenAnswer((_) async => right(false));
    final sub = container.listen(calendarSettingsControllerProvider, (_, _) {});
    addTearDown(sub.close);

    final result = await controller().loadCalendars();

    expect(result, isNull);
    expect(
      container.read(calendarSettingsControllerProvider).error,
      const CalendarFailure(CalendarReason.accessDenied),
    );
    verifyNever(() => calendar.listCalendars());
  });

  test('accès accordé renvoie la liste des calendriers', () async {
    const calendars = [
      DeviceCalendar(id: 'c1', title: 'Famille', source: 'iCloud'),
    ];
    when(() => calendar.requestAccess()).thenAnswer((_) async => right(true));
    when(() => calendar.listCalendars())
        .thenAnswer((_) async => right(calendars));
    final sub = container.listen(calendarSettingsControllerProvider, (_, _) {});
    addTearDown(sub.close);

    final result = await controller().loadCalendars();

    expect(result, calendars);
    expect(
      container.read(calendarSettingsControllerProvider),
      const AsyncData<void>(null),
    );
  });

  test('choose mémorise le choix puis synchronise', () async {
    await controller().choose(
      const DeviceCalendar(id: 'c1', title: 'Famille', source: 'iCloud'),
    );

    expect(
      container.read(selectedCalendarProvider),
      const CalendarChoice(id: 'c1', title: 'Famille'),
    );
    verify(() => sync.sync()).called(1);
  });

  test('clear efface le choix', () async {
    await container
        .read(selectedCalendarProvider.notifier)
        .choose(const CalendarChoice(id: 'c1', title: 'Famille'));

    await controller().clear();

    expect(container.read(selectedCalendarProvider), isNull);
  });
}
