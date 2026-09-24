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

  /// Date du RDV pris : celle de la visite d'une étape, ou celle du RDV libre.
  DateTime? get appointmentAt => switch (this) {
    StageItem(:final entry) => entry.visit?.appointmentAt,
    AppointmentItem(:final appointment) => appointment.appointmentAt,
  };

  /// Praticien saisi, `null` s'il est absent ou vide.
  String? get practitioner {
    final raw = switch (this) {
      StageItem(:final entry) => entry.visit?.practitioner,
      AppointmentItem(:final appointment) => appointment.practitioner,
    };
    final trimmed = raw?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
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

  /// RDV programmés, du plus proche au plus lointain ; à date égale, l'ordre
  /// de [items] est conservé.
  List<MedicalTimelineItem> get scheduled =>
      _byAppointment(_withStatus(MedicalStageStatus.scheduled));

  /// Prochain RDV programmé, ou `null`.
  MedicalTimelineItem? get nextAppointment => scheduled.firstOrNull;

  /// RDV passés pas encore marqués faits, du plus ancien au plus récent.
  List<MedicalTimelineItem> get awaitingConfirmation =>
      _byAppointment(_withStatus(MedicalStageStatus.appointmentPassed));

  /// Étapes à caler : en retard d'abord, puis à faire, chacune dans l'ordre
  /// de [items].
  List<MedicalTimelineItem> get toSchedule => [
    ..._withStatus(MedicalStageStatus.late),
    ..._withStatus(MedicalStageStatus.due),
  ];

  /// Étapes à venir, ordre de [items].
  List<MedicalTimelineItem> get upcoming =>
      _withStatus(MedicalStageStatus.upcoming);

  /// Étapes faites, ordre de [items].
  List<MedicalTimelineItem> get done => _withStatus(MedicalStageStatus.done);

  List<MedicalTimelineItem> _withStatus(MedicalStageStatus status) => [
    for (final item in items)
      if (item.status == status) item,
  ];

  /// Tri stable par [MedicalTimelineItem.appointmentAt] ; un élément sans
  /// date (incohérence de données) passe en dernier.
  static List<MedicalTimelineItem> _byAppointment(
    List<MedicalTimelineItem> list,
  ) {
    final indexed = list.indexed.toList()
      ..sort((a, b) {
        final (ia, itemA) = a;
        final (ib, itemB) = b;
        final dateA = itemA.appointmentAt;
        final dateB = itemB.appointmentAt;
        final byDate = switch ((dateA, dateB)) {
          (null, null) => 0,
          (null, _) => 1,
          (_, null) => -1,
          (final da?, final db?) => da.compareTo(db),
        };
        return byDate != 0 ? byDate : ia.compareTo(ib);
      });
    return [for (final (_, item) in indexed) item];
  }

  static int _compareAppointments(AppointmentItem a, AppointmentItem b) {
    final byDate = a.appointment.appointmentAt.compareTo(
      b.appointment.appointmentAt,
    );
    return byDate != 0 ? byDate : a.appointment.id.compareTo(b.appointment.id);
  }
}
