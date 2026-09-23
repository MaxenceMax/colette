import 'dart:developer' as developer;

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:colette/features/health/domain/entities/device_calendar.dart';
import 'package:colette/features/health/domain/repositories/calendar_repository.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

const _reasons = {
  'accessDenied': CalendarReason.accessDenied,
  'calendarNotFound': CalendarReason.calendarNotFound,
  'io': CalendarReason.io,
};

/// Calendrier iOS via le pont Swift `CalendarPlugin` ; dates en millisecondes.
class NativeCalendarRepository implements CalendarRepository {
  const NativeCalendarRepository(this._channel);

  /// Nom du canal, partagé avec `CalendarPlugin.swift`.
  static const channelName = 'colette/calendar';

  final MethodChannel _channel;

  Future<Either<Failure, T>> _call<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } catch (e, stackTrace) {
      if (e is PlatformException) {
        if (_reasons[e.code] case final reason?) {
          return left(CalendarFailure(reason));
        }
      }
      developer.log(
        'Calendrier natif',
        error: e,
        stackTrace: stackTrace,
        name: 'colette',
      );
      return left(UnknownFailure(e, stackTrace));
    }
  }

  static DateTime _date(Object? millis) =>
      DateTime.fromMillisecondsSinceEpoch((millis! as num).toInt());

  @override
  Future<Either<Failure, bool>> requestAccess() => _call(
    () async => await _channel.invokeMethod<bool>('requestAccess') ?? false,
  );

  @override
  Future<Either<Failure, List<DeviceCalendar>>> listCalendars() =>
      _call(() async {
        final raw = await _channel.invokeListMethod<Object?>('listCalendars');
        return [
          for (final item in raw ?? const <Object?>[])
            if (item case final Map<Object?, Object?> map)
              DeviceCalendar(
                id: map['id']! as String,
                title: map['title']! as String,
                colorHex: map['colorHex'] as String?,
                source: map['source']! as String,
              ),
        ];
      });

  @override
  Future<Either<Failure, List<CalendarEvent>>> findEvents(
    String calendarId, {
    required DateTime from,
    required DateTime to,
  }) => _call(() async {
    final raw = await _channel.invokeListMethod<Object?>('findEvents', {
      'calendarId': calendarId,
      'from': from.millisecondsSinceEpoch,
      'to': to.millisecondsSinceEpoch,
    });
    return [
      for (final item in raw ?? const <Object?>[])
        if (item case final Map<Object?, Object?> map)
          CalendarEvent(
            eventId: map['eventId']! as String,
            url: map['url']! as String,
            title: map['title']! as String,
            start: _date(map['start']),
            end: _date(map['end']),
            notes: map['notes'] as String?,
            externalId: map['externalId'] as String?,
          ),
    ];
  });

  @override
  Future<Either<Failure, String>> upsertEvent(
    String calendarId, {
    String? eventId,
    required CalendarEventDraft draft,
  }) => _call(() async {
    final id = await _channel.invokeMethod<String>('upsertEvent', {
      'calendarId': calendarId,
      'eventId': ?eventId,
      'url': draft.url,
      'title': draft.title,
      'start': draft.start.millisecondsSinceEpoch,
      'end': draft.end.millisecondsSinceEpoch,
      'notes': ?draft.notes,
      'alarms': [
        for (final alarm in draft.alarms) alarm.millisecondsSinceEpoch,
      ],
    });
    return id!;
  });

  @override
  Future<Either<Failure, void>> deleteEvent(
    String calendarId,
    String eventId,
  ) => _call(
    () => _channel.invokeMethod<void>('deleteEvent', {
      'calendarId': calendarId,
      'eventId': eventId,
    }),
  );
}
