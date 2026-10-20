import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/events/domain/entities/care_day_summary.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';

/// Bilan de chaque jour civil où commence au moins un soin, clé à minuit.
Map<DateTime, CareDaySummary> summarizeCareDays(List<CareEvent> events) {
  final summaries = <DateTime, CareDaySummary>{};
  for (final event in events) {
    final day = event.startAt.dateOnly;
    final current = summaries[day] ?? const CareDaySummary();
    summaries[day] = current.copyWith(
      bottleMl: current.bottleMl + (event.bottleMl ?? 0),
      bottleCount: current.bottleCount + (event.hasBottle ? 1 : 0),
      diapers: current.diapers + (event.diaperChange ? 1 : 0),
      pee: current.pee + (event.pee ? 1 : 0),
    );
  }
  return summaries;
}
