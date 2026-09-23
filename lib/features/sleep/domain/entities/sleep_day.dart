import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sleep_day.freezed.dart';

/// Portion d'un sommeil comprise dans un jour civil.
@freezed
abstract class SleepSegment with _$SleepSegment {
  const factory SleepSegment({
    required DateTime start,
    required DateTime end,
    required SleepKind kind,
  }) = _SleepSegment;
}

/// Sommeil d'un jour civil : segments, total, siestes, plus longue période.
@freezed
abstract class SleepDay with _$SleepDay {
  const factory SleepDay({
    required DateTime day,
    required List<SleepSegment> segments,
    required Duration total,
    required int napCount,
    required Duration longest,
  }) = _SleepDay;
}
