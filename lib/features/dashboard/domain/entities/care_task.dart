import 'package:colette/shared/domain/care_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_task.freezed.dart';

/// Un soin attendu aujourd'hui et son avancement.
@freezed
abstract class CareTask with _$CareTask {
  const CareTask._();

  const factory CareTask({
    required CareType type,
    required int target,
    required int done,
    DateTime? lastDoneAt,
  }) = _CareTask;

  bool get isDone => done >= target;
}
