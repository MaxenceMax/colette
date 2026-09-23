import 'package:colette/features/health/domain/entities/custom_appointment.dart';
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

/// Élément de la frise : étape du calendrier ou RDV libre.
@freezed
sealed class MedicalTimelineItem with _$MedicalTimelineItem {
  const MedicalTimelineItem._();

  const factory MedicalTimelineItem.stage(MedicalTimelineEntry entry) =
      StageItem;
  const factory MedicalTimelineItem.appointment(
    CustomAppointment appointment,
    MedicalStageStatus status,
  ) = AppointmentItem;

  MedicalStageStatus get status => switch (this) {
    StageItem(:final entry) => entry.status,
    AppointmentItem(status: final s) => s,
  };

  /// Date de tri : début de fenêtre d'une étape, date d'un RDV libre.
  DateTime get anchorDate => switch (this) {
    StageItem(:final entry) => entry.dueFrom,
    AppointmentItem(:final appointment) => appointment.appointmentAt,
  };
}

/// Étapes du calendrier dans l'ordre des âges, plus les RDV libres datés.
@freezed
abstract class MedicalTimeline with _$MedicalTimeline {
  const MedicalTimeline._();

  const factory MedicalTimeline({
    required List<MedicalTimelineEntry> entries,
    @Default(<AppointmentItem>[]) List<AppointmentItem> appointments,
  }) = _MedicalTimeline;

  /// Étapes dans leur ordre ; chaque RDV libre est inséré avant la première
  /// étape dont `dueFrom` est strictement postérieur à sa date (après la
  /// dernière sinon). RDV libres triés par date puis identifiant.
  List<MedicalTimelineItem> get items {
    final pending = [...appointments]..sort(_compareAppointments);
    final result = <MedicalTimelineItem>[];
    for (final entry in entries) {
      while (pending.isNotEmpty &&
          !pending.first.anchorDate.isAfter(entry.dueFrom)) {
        result.add(pending.removeAt(0));
      }
      result.add(MedicalTimelineItem.stage(entry));
    }
    return result..addAll(pending);
  }

  /// Premier élément non fait, ou `null`.
  MedicalTimelineItem? get next =>
      items.where((i) => i.status != MedicalStageStatus.done).firstOrNull;

  static int _compareAppointments(AppointmentItem a, AppointmentItem b) {
    final byDate = a.appointment.appointmentAt.compareTo(
      b.appointment.appointmentAt,
    );
    return byDate != 0 ? byDate : a.appointment.id.compareTo(b.appointment.id);
  }
}
