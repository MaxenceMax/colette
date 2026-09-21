import 'package:freezed_annotation/freezed_annotation.dart';

part 'weight_entry.freezed.dart';

/// Une pesée.
@freezed
abstract class WeightEntry with _$WeightEntry {
  const factory WeightEntry({
    required String id,
    required DateTime measuredAt,
    required int grams,
  }) = _WeightEntry;
}
