import 'package:colette/core/result/either_extensions.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/data/native_calendar_repository.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:colette/features/health/domain/entities/device_calendar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(NativeCalendarRepository.channelName);
  late List<MethodCall> calls;
  const repo = NativeCalendarRepository(channel);

  void mock(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  }

  setUp(() => calls = []);

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('requestAccess renvoie le booléen natif', () async {
    mock((_) => true);
    expect((await repo.requestAccess()).getRight().toNullable(), isTrue);
    expect(calls.single.method, 'requestAccess');
  });

  test('listCalendars décode les calendriers', () async {
    mock(
      (_) => [
        {
          'id': 'c1',
          'title': 'Famille',
          'colorHex': '#FF8800',
          'source': 'iCloud',
        },
      ],
    );
    expect((await repo.listCalendars()).getRight().toNullable(), [
      const DeviceCalendar(
        id: 'c1',
        title: 'Famille',
        colorHex: '#FF8800',
        source: 'iCloud',
      ),
    ]);
  });

  test('findEvents envoie la fenêtre en millisecondes et décode', () async {
    final start = DateTime(2026, 11, 3, 10);
    mock(
      (_) => [
        {
          'eventId': 'e1',
          'url': 'colette://rdv/m2',
          'title': 'Examen',
          'start': start.millisecondsSinceEpoch,
          'end': start.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
          'notes': 'Dr Martin',
          'externalId': 'uid-1',
        },
      ],
    );
    final from = DateTime(2026, 10, 19);
    final to = DateTime(2028, 10, 20);
    final events = (await repo.findEvents(
      'c1',
      from: from,
      to: to,
    )).getRight().toNullable()!;
    expect(calls.single.arguments, {
      'calendarId': 'c1',
      'from': from.millisecondsSinceEpoch,
      'to': to.millisecondsSinceEpoch,
    });
    expect(
      events.single,
      CalendarEvent(
        eventId: 'e1',
        url: 'colette://rdv/m2',
        title: 'Examen',
        start: start,
        end: start.add(const Duration(minutes: 30)),
        notes: 'Dr Martin',
        externalId: 'uid-1',
      ),
    );
  });

  test('upsertEvent envoie le brouillon et renvoie l\'identifiant', () async {
    mock((_) => 'e9');
    final start = DateTime(2026, 11, 3, 10);
    final result = await repo.upsertEvent(
      'c1',
      eventId: 'e1',
      draft: CalendarEventDraft(
        url: 'colette://rdv/m2',
        title: 'Examen',
        start: start,
        end: start.add(const Duration(minutes: 30)),
        alarms: [DateTime(2026, 11, 2, 18)],
      ),
    );
    expect(result.getRight().toNullable(), 'e9');
    expect(calls.single.arguments, {
      'calendarId': 'c1',
      'eventId': 'e1',
      'url': 'colette://rdv/m2',
      'title': 'Examen',
      'start': start.millisecondsSinceEpoch,
      'end': start.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
      'alarms': [DateTime(2026, 11, 2, 18).millisecondsSinceEpoch],
    });
  });

  test('codes d\'erreur natifs traduits en CalendarFailure', () async {
    for (final (code, reason) in [
      ('accessDenied', CalendarReason.accessDenied),
      ('calendarNotFound', CalendarReason.calendarNotFound),
      ('io', CalendarReason.io),
    ]) {
      mock((_) => throw PlatformException(code: code));
      expect(
        (await repo.deleteEvent('c1', 'e1')).leftOrNull,
        CalendarFailure(reason),
      );
    }
  });
}
