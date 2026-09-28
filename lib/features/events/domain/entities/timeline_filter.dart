import 'package:colette/features/events/domain/entities/event_tag.dart';
import 'package:colette/shared/domain/care_type.dart';

/// Filtre du Journal : tout, un soin, les biberons ou les sommeils.
sealed class TimelineFilter {
  const TimelineFilter();

  /// Filtres dans l'ordre des puces du Journal.
  static const List<TimelineFilter> values = [
    AllEntriesFilter(),
    BottleFilter(),
    CareTypeFilter(CareType.poop),
    CareTypeFilter(CareType.pee),
    CareTypeFilter(CareType.diaperChange),
    SleepFilter(),
    CareTypeFilter(CareType.bath),
    CareTypeFilter(CareType.adrigyl),
    CareTypeFilter(CareType.eyeCare),
    CareTypeFilter(CareType.noseCare),
    CareTypeFilter(CareType.umbilicalCare),
  ];

  /// `true` si le Journal affiche des soins avec ce filtre.
  bool get showsCares => this is! SleepFilter;

  /// `true` si le Journal affiche des sommeils avec ce filtre.
  bool get showsSleeps => this is AllEntriesFilter || this is SleepFilter;

  /// Critère transmis au dépôt de soins ; `null` quand aucun tri n'est requis.
  EventTag? get eventTag => switch (this) {
    CareTypeFilter(:final type) => CareTag(type),
    BottleFilter() => const BottleTag(),
    AllEntriesFilter() || SleepFilter() => null,
  };

  /// `true` si la dernière page paginée est pleine : il reste peut-être plus
  /// ancien à charger. Les sommeils sont paginés seuls avec [SleepFilter].
  bool isLastPageFull({
    required int cares,
    required int sleeps,
    required int limit,
  }) => (this is SleepFilter ? sleeps : cares) >= limit;
}

/// Soins et sommeils, sans filtre.
final class AllEntriesFilter extends TimelineFilter {
  const AllEntriesFilter();
}

/// Soins où [type] est coché.
final class CareTypeFilter extends TimelineFilter {
  const CareTypeFilter(this.type);

  final CareType type;

  @override
  bool operator ==(Object other) =>
      other is CareTypeFilter && other.type == type;

  @override
  int get hashCode => type.hashCode;
}

/// Soins avec un biberon.
final class BottleFilter extends TimelineFilter {
  const BottleFilter();
}

/// Sommeils seuls.
final class SleepFilter extends TimelineFilter {
  const SleepFilter();
}
