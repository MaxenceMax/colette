import 'dart:convert';

import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';

/// Conversion `BottleTimerSession` ↔ JSON local (dates en millisecondes).
abstract final class BottleTimerSessionDto {
  static String encode(BottleTimerSession session) => jsonEncode({
    'startedAt': _ms(session.run.startedAt),
    'feedingEndsAt': _ms(session.run.feedingEndsAt),
    'editing': session.editing,
    'draft': _draftToMap(session.draft),
  });

  /// Lève une exception si [raw] est illisible (convertie par `guard()`).
  static BottleTimerSession decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return BottleTimerSession(
      run: BottleTimerRun(
        startedAt: _date(map['startedAt']),
        feedingEndsAt: _date(map['feedingEndsAt']),
      ),
      editing: map['editing'] as bool,
      draft: _draftFromMap(map['draft'] as Map<String, dynamic>),
    );
  }

  static int _ms(DateTime date) => date.millisecondsSinceEpoch;

  static DateTime _date(Object? ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms! as int);

  static Map<String, dynamic> _draftToMap(CareEvent e) => {
    'id': e.id,
    'startAt': _ms(e.startAt),
    'endAt': _ms(e.endAt),
    'pee': e.pee,
    'poop': e.poop,
    'diaperChange': e.diaperChange,
    'adrigyl': e.adrigyl,
    'bath': e.bath,
    'eyeCare': e.eyeCare,
    'noseCare': e.noseCare,
    'umbilicalCare': e.umbilicalCare,
    'bottleMl': e.bottleMl,
    'note': e.note,
    'createdByDeviceId': e.createdByDeviceId,
    'createdAt': _ms(e.createdAt),
    'updatedAt': _ms(e.updatedAt),
  };

  static CareEvent _draftFromMap(Map<String, dynamic> m) => CareEvent(
    id: m['id'] as String,
    startAt: _date(m['startAt']),
    endAt: _date(m['endAt']),
    pee: m['pee'] as bool,
    poop: m['poop'] as bool,
    diaperChange: m['diaperChange'] as bool,
    adrigyl: m['adrigyl'] as bool,
    bath: m['bath'] as bool,
    eyeCare: m['eyeCare'] as bool,
    noseCare: m['noseCare'] as bool,
    umbilicalCare: m['umbilicalCare'] as bool,
    bottleMl: m['bottleMl'] as int?,
    note: m['note'] as String?,
    createdByDeviceId: m['createdByDeviceId'] as String,
    createdAt: _date(m['createdAt']),
    updatedAt: _date(m['updatedAt']),
  );
}
