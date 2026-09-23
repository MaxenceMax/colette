import 'package:colette/features/health/data/native_calendar_repository.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// À lancer sur simulateur après avoir accordé l'accès au Calendrier :
/// `xcrun simctl privacy booted grant calendar fr.montet.colette`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const repo = NativeCalendarRepository(
    MethodChannel(NativeCalendarRepository.channelName),
  );

  testWidgets('créer, retrouver, modifier puis supprimer un événement', (
    _,
  ) async {
    expect((await repo.requestAccess()).getRight().toNullable(), isTrue);
    final calendars = (await repo.listCalendars()).getRight().toNullable()!;
    expect(calendars, isNotEmpty);
    final calendarId = calendars.first.id;
    final start = DateTime.now().add(const Duration(days: 3));
    final draft = CalendarEventDraft(
      url: 'colette://rdv/m2',
      title: 'Test Colette',
      start: start,
      end: start.add(const Duration(minutes: 30)),
      notes: 'Dr Test',
      alarms: [start.subtract(const Duration(hours: 1))],
    );
    final from = DateTime.now().subtract(const Duration(days: 1));
    final to = DateTime.now().add(const Duration(days: 30));

    final eventId = (await repo.upsertEvent(
      calendarId,
      draft: draft,
    )).getRight().toNullable()!;
    var found = (await repo.findEvents(
      calendarId,
      from: from,
      to: to,
    )).getRight().toNullable()!;
    expect(found.where((e) => e.eventId == eventId).single.notes, 'Dr Test');

    await repo.upsertEvent(
      calendarId,
      eventId: eventId,
      draft: draft.copyWith(title: 'Test Colette modifié'),
    );
    found = (await repo.findEvents(
      calendarId,
      from: from,
      to: to,
    )).getRight().toNullable()!;
    expect(
      found.where((e) => e.eventId == eventId).single.title,
      'Test Colette modifié',
    );

    expect((await repo.deleteEvent(calendarId, eventId)).isRight(), isTrue);
    found = (await repo.findEvents(
      calendarId,
      from: from,
      to: to,
    )).getRight().toNullable()!;
    expect(found.where((e) => e.eventId == eventId), isEmpty);
  });
}
