import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/health/domain/entities/device_calendar.dart';
import 'package:colette/features/health/domain/repositories/calendar_repository.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/health/presentation/widgets/calendar_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump_app.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

void main() {
  late MockCalendarRepository calendar;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    calendar = MockCalendarRepository();
  });

  List<Override> overrides() => [
    sharedPreferencesProvider.overrideWithValue(prefs),
    calendarRepositoryProvider.overrideWithValue(calendar),
    healthSyncProvider.overrideWithValue(const NoopHealthSync()),
  ];

  testWidgets('choisir un calendrier le mémorise', (tester) async {
    when(() => calendar.requestAccess()).thenAnswer((_) async => right(true));
    when(() => calendar.listCalendars()).thenAnswer(
      (_) async => right(const [
        DeviceCalendar(id: 'c1', title: 'Famille', source: 'iCloud'),
      ]),
    );
    await pumpApp(
      tester,
      const Scaffold(body: CalendarSettingsSection()),
      overrides: overrides(),
    );
    expect(
      find.text(
        'Les RDV santé ne sont pas ajoutés au Calendrier de cet iPhone.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Choisir un calendrier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Famille'));
    await tester.pumpAndSettle();
    expect(find.text('RDV santé ajoutés à : Famille'), findsOneWidget);
    expect(prefs.getString(SelectedCalendar.idKey), 'c1');
  });

  testWidgets("accès refusé : message d'erreur", (tester) async {
    when(() => calendar.requestAccess()).thenAnswer((_) async => right(false));
    await pumpApp(
      tester,
      const Scaffold(body: CalendarSettingsSection()),
      overrides: overrides(),
    );
    await tester.tap(find.text('Choisir un calendrier'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Colette n'a pas accès au Calendrier. Autorise-le dans Réglages iOS › Colette › Calendriers.",
      ),
      findsOneWidget,
    );
    verifyNever(() => calendar.listCalendars());
  });

  testWidgets('ne plus synchroniser efface le choix', (tester) async {
    await prefs.setString(SelectedCalendar.idKey, 'c1');
    await prefs.setString(SelectedCalendar.titleKey, 'Famille');
    await pumpApp(
      tester,
      const Scaffold(body: CalendarSettingsSection()),
      overrides: overrides(),
    );
    await tester.tap(find.text('Ne plus synchroniser'));
    await tester.pumpAndSettle();
    expect(find.text('Choisir un calendrier'), findsOneWidget);
    expect(prefs.getString(SelectedCalendar.idKey), isNull);
  });
}
