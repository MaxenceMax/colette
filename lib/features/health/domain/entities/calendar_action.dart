import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_action.freezed.dart';

/// Opération à exécuter sur le Calendrier iOS.
@freezed
sealed class CalendarAction with _$CalendarAction {
  const factory CalendarAction.create(CalendarEventDraft draft) =
      CreateCalendarEvent;
  const factory CalendarAction.update(
    String eventId,
    CalendarEventDraft draft,
  ) = UpdateCalendarEvent;
  const factory CalendarAction.delete(String eventId) = DeleteCalendarEvent;
}
