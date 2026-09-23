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
    final until = windowEnd(now);
    final wanted = <String, CalendarEventDraft>{
      for (final visit in visits)
        if (visit.appointmentAt case final at?
            when visit.doneAt == null &&
                !at.isBefore(from) &&
                at.isBefore(until))
          urlOf(visit.stageId): _draft(visit, at, titleOf(visit.stageId), now),
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
      final ordered = [...existing]..sort(_compareForKeep);
      final kept = ordered.first;
      if (_differs(kept, draft)) {
        actions.add(CalendarAction.update(kept.eventId, draft));
      }
      for (final extra in ordered.skip(1)) {
        actions.add(CalendarAction.delete(extra.eventId));
      }
    }
    for (final orphan in byUrl.values.expand((e) => e)) {
      actions.add(CalendarAction.delete(orphan.eventId));
    }
    return actions;
  }

  /// Doublon : garde le plus petit `externalId` (UID iCloud, identique sur les deux iPhones) ; les absents passent après, `eventId` en dernier recours.
  static int _compareForKeep(CalendarEvent a, CalendarEvent b) {
    final cmp = switch ((a.externalId, b.externalId)) {
      (null, null) => 0,
      (null, _) => 1,
      (_, null) => -1,
      (final x?, final y?) => x.compareTo(y),
    };
    return cmp != 0 ? cmp : a.eventId.compareTo(b.eventId);
  }

  static CalendarEventDraft _draft(
    MedicalVisit visit,
    DateTime at,
    String title,
    DateTime now,
  ) {
    final start = DateTime(at.year, at.month, at.day, at.hour, at.minute);
    final alarms = [
      DateTime(start.year, start.month, start.day - 1, eveAlarmHour),
      start.subtract(lastAlarmBefore),
    ].where((alarm) => alarm.isAfter(now)).toList();
    return CalendarEventDraft(
      url: urlOf(visit.stageId),
      title: title,
      start: start,
      end: start.add(eventDuration),
      notes: visit.practitioner,
      alarms: alarms,
    );
  }

  /// Comparaison à la minute : Firestore garde les secondes, EventKit les tronque.
  static bool _differs(CalendarEvent event, CalendarEventDraft draft) =>
      event.title != draft.title ||
      (event.notes ?? '') != (draft.notes ?? '') ||
      !_sameMinute(event.start, draft.start) ||
      !_sameMinute(event.end, draft.end);

  static bool _sameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;
}
