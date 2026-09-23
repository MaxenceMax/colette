import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_event.freezed.dart';

/// Événement Colette lu dans le Calendrier iOS (URL `colette://rdv/…`).
@freezed
abstract class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent({
    required String eventId,
    required String url,
    required String title,
    required DateTime start,
    required DateTime end,
    String? notes,
  }) = _CalendarEvent;
}

/// Contenu voulu d'un événement ; [alarms] : instants des alertes.
@freezed
abstract class CalendarEventDraft with _$CalendarEventDraft {
  const factory CalendarEventDraft({
    required String url,
    required String title,
    required DateTime start,
    required DateTime end,
    String? notes,
    @Default(<DateTime>[]) List<DateTime> alarms,
  }) = _CalendarEventDraft;
}
