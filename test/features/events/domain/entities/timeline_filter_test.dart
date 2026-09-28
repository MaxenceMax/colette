import 'package:colette/features/events/domain/entities/event_tag.dart';
import 'package:colette/features/events/domain/entities/timeline_filter.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('values suit l\'ordre des puces', () {
    expect(TimelineFilter.values, const [
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
    ]);
  });

  test('CareTypeFilter est égal par type', () {
    expect(
      const CareTypeFilter(CareType.poop),
      const CareTypeFilter(CareType.poop),
    );
    expect(
      const CareTypeFilter(CareType.poop),
      isNot(const CareTypeFilter(CareType.pee)),
    );
    expect(
      const CareTypeFilter(CareType.poop).hashCode,
      const CareTypeFilter(CareType.poop).hashCode,
    );
  });

  test('showsCares et showsSleeps', () {
    expect(const AllEntriesFilter().showsCares, isTrue);
    expect(const AllEntriesFilter().showsSleeps, isTrue);
    expect(const SleepFilter().showsCares, isFalse);
    expect(const SleepFilter().showsSleeps, isTrue);
    expect(const BottleFilter().showsCares, isTrue);
    expect(const BottleFilter().showsSleeps, isFalse);
    expect(const CareTypeFilter(CareType.poop).showsCares, isTrue);
    expect(const CareTypeFilter(CareType.poop).showsSleeps, isFalse);
  });

  test('eventTag traduit le filtre en critère de soin', () {
    expect(const AllEntriesFilter().eventTag, isNull);
    expect(const SleepFilter().eventTag, isNull);
    expect(const BottleFilter().eventTag, const BottleTag());
    expect(
      const CareTypeFilter(CareType.poop).eventTag,
      const CareTag(CareType.poop),
    );
  });

  test('isLastPageFull compte les sommeils avec SleepFilter', () {
    expect(
      const SleepFilter().isLastPageFull(cares: 0, sleeps: 30, limit: 30),
      isTrue,
    );
    expect(
      const SleepFilter().isLastPageFull(cares: 30, sleeps: 3, limit: 30),
      isFalse,
    );
  });

  test('isLastPageFull compte les soins sinon', () {
    expect(
      const AllEntriesFilter().isLastPageFull(cares: 30, sleeps: 0, limit: 30),
      isTrue,
    );
    expect(
      const CareTypeFilter(CareType.poop)
          .isLastPageFull(cares: 12, sleeps: 40, limit: 30),
      isFalse,
    );
  });
}
