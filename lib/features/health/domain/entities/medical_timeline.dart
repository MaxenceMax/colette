import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'medical_timeline.freezed.dart';

/// Une étape datée pour ce bébé, avec son statut et sa visite éventuelle.
@freezed
abstract class MedicalTimelineEntry with _$MedicalTimelineEntry {
  const factory MedicalTimelineEntry({
    required MedicalStage stage,
    required DateTime dueFrom,
    required DateTime dueUntil,
    required MedicalStageStatus status,
    MedicalVisit? visit,
  }) = _MedicalTimelineEntry;
}

/// Toutes les étapes du calendrier, dans l'ordre des âges.
@freezed
abstract class MedicalTimeline with _$MedicalTimeline {
  const MedicalTimeline._();

  const factory MedicalTimeline({required List<MedicalTimelineEntry> entries}) =
      _MedicalTimeline;

  /// Première étape non faite, ou `null`.
  MedicalTimelineEntry? get next =>
      entries.where((e) => e.status != MedicalStageStatus.done).firstOrNull;
}
