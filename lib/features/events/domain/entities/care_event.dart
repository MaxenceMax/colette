import 'package:colette/shared/domain/care_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_event.freezed.dart';

/// Un événement de soin : une plage horaire et des soins cochés.
@freezed
abstract class CareEvent with _$CareEvent {
  const CareEvent._();

  const factory CareEvent({
    required String id,
    required DateTime startAt,
    required DateTime endAt,
    @Default(false) bool pee,
    @Default(false) bool poop,
    @Default(false) bool diaperChange,
    @Default(false) bool adrigyl,
    @Default(false) bool bath,
    @Default(false) bool eyeCare,
    @Default(false) bool noseCare,
    @Default(false) bool umbilicalCare,
    int? bottleMl,
    String? note,
    required String createdByDeviceId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CareEvent;

  /// `true` si [type] est coché.
  bool has(CareType type) => switch (type) {
    CareType.pee => pee,
    CareType.poop => poop,
    CareType.diaperChange => diaperChange,
    CareType.adrigyl => adrigyl,
    CareType.bath => bath,
    CareType.eyeCare => eyeCare,
    CareType.noseCare => noseCare,
    CareType.umbilicalCare => umbilicalCare,
  };

  /// Copie avec [type] mis à [value].
  CareEvent toggle(CareType type, bool value) => switch (type) {
    CareType.pee => copyWith(pee: value),
    CareType.poop => copyWith(poop: value),
    CareType.diaperChange => copyWith(diaperChange: value),
    CareType.adrigyl => copyWith(adrigyl: value),
    CareType.bath => copyWith(bath: value),
    CareType.eyeCare => copyWith(eyeCare: value),
    CareType.noseCare => copyWith(noseCare: value),
    CareType.umbilicalCare => copyWith(umbilicalCare: value),
  };

  bool get hasBottle => bottleMl != null;

  List<CareType> get checkedCares => CareType.values.where(has).toList();

  bool get isEmpty => checkedCares.isEmpty && !hasBottle;
}
