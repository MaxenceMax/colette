import 'package:colette/features/health/domain/entities/calendar_action.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';

/// Actions pour qu'un calendrier contienne exactement un événement par RDV à venir.
class ReconcileCalendar {
  const ReconcileCalendar();

  static const urlPrefix = 'colette://rdv/';
  static const eventDuration = Duration(minutes: 30);

  /// Heure de l'alerte de la veille.
  static const eveAlarmHour = 18;
  static const lastAlarmBefore = Duration(hours: 1);

  static String urlOf(MedicalStageId id) => '$urlPrefix${id.name}';

  /// Début de la fenêtre lue et gérée : minuit d'hier.
  static DateTime windowStart(DateTime now) =>
      DateTime(now.year, now.month, now.day - 1);

  /// Fin de la fenêtre lue : deux ans plus tard.
  static DateTime windowEnd(DateTime now) =>
      DateTime(now.year + 2, now.month, now.day);

  List<CalendarAction> call({
    required List<MedicalVisit> visits,
    required List<CalendarEvent> events,
    required String Function(MedicalStageId id) titleOf,
    required DateTime now,
  }) {
    final from = windowStart(now);
    final wanted = <String, CalendarEventDraft>{
      for (final visit in visits)
        if (visit.appointmentAt case final at?
            when visit.doneAt == null && !at.isBefore(from))
          urlOf(visit.stageId): _draft(visit, at, titleOf(visit.stageId)),
    };
    final byUrl = <String, List<CalendarEvent>>{};
    for (final event in events) {
      (byUrl[event.url] ??= []).add(event);
    }
    final actions = <CalendarAction>[];
    for (final MapEntry(key: url, value: draft) in wanted.entries) {
      final existing = byUrl.remove(url) ?? const <CalendarEvent>[];
      if (existing.isEmpty) {
        actions.add(CalendarAction.create(draft));
        continue;
      }
      final kept = existing.first;
      if (_differs(kept, draft)) {
        actions.add(CalendarAction.update(kept.eventId, draft));
      }
      for (final extra in existing.skip(1)) {
        actions.add(CalendarAction.delete(extra.eventId));
      }
    }
    for (final orphan in byUrl.values.expand((e) => e)) {
      actions.add(CalendarAction.delete(orphan.eventId));
    }
    return actions;
  }

  static CalendarEventDraft _draft(
    MedicalVisit visit,
    DateTime at,
    String title,
  ) => CalendarEventDraft(
    url: urlOf(visit.stageId),
    title: title,
    start: at,
    end: at.add(eventDuration),
    notes: visit.practitioner,
    alarms: [
      DateTime(at.year, at.month, at.day - 1, eveAlarmHour),
      at.subtract(lastAlarmBefore),
    ],
  );

  /// Comparaison à la milliseconde : Firestore et EventKit n'ont pas la même précision.
  static bool _differs(CalendarEvent event, CalendarEventDraft draft) =>
      event.title != draft.title ||
      (event.notes ?? '') != (draft.notes ?? '') ||
      event.start.millisecondsSinceEpoch !=
          draft.start.millisecondsSinceEpoch ||
      event.end.millisecondsSinceEpoch != draft.end.millisecondsSinceEpoch;
}
