import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tooth_record.freezed.dart';

/// Ce que les parents ont noté pour une dent : sortie, chute, note.
@freezed
abstract class ToothRecord with _$ToothRecord {
  const ToothRecord._();

  const factory ToothRecord({
    required ToothId toothId,
    DateTime? eruptedAt,
    DateTime? lostAt,
    String? note,
    required DateTime updatedAt,
    required String updatedByDeviceId,
  }) = _ToothRecord;

  /// Rien de noté : ni date, ni note.
  bool get isEmpty =>
      eruptedAt == null && lostAt == null && (note?.trim().isEmpty ?? true);
}
