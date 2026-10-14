import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/entities/tooth_status.dart';

/// État d'une dent d'après ce qui a été noté ; `null` = rien de noté.
class ComputeToothStatus {
  const ComputeToothStatus();

  /// Une chute sans date de sortie compte : la dent a pu sortir avant l'app.
  ToothStatus call(ToothRecord? record) => switch (record) {
    ToothRecord(lostAt: _?) => ToothStatus.lost,
    ToothRecord(eruptedAt: _?) => ToothStatus.erupted,
    _ => ToothStatus.absent,
  };
}
