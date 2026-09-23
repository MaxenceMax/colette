import 'package:colette/core/result/failure.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_sync_issue.g.dart';

/// Dernier échec bloquant de la synchronisation du calendrier ; `null` si tout va bien.
@Riverpod(keepAlive: true)
class CalendarSyncIssue extends _$CalendarSyncIssue {
  @override
  CalendarReason? build() => null;

  void report(CalendarReason reason) => state = reason;

  void clear() => state = null;
}
