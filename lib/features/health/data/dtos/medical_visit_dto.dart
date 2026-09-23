import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';

/// Conversion `MedicalVisit` ↔ document `medicalVisits/{stageId}` ; clés absentes plutôt que nulles.
abstract final class MedicalVisitDto {
  static final _stages = MedicalStageId.values.asNameMap();
  static final _vaccines = VaccineCode.values.asNameMap();

  static Map<String, dynamic> toMap(MedicalVisit v) => {
    if (v.appointmentAt case final at?) 'appointmentAt': Timestamp.fromDate(at),
    'practitioner': ?v.practitioner,
    if (v.doneAt case final at?) 'doneAt': Timestamp.fromDate(at),
    'note': ?v.note,
    if (v.vaccines.isNotEmpty)
      'vaccines': {
        for (final MapEntry(:key, :value) in v.vaccines.entries)
          key.name: {
            'givenAt': Timestamp.fromDate(value.givenAt),
            'brand': ?value.brand,
            'lot': ?value.lot,
          },
      },
    'updatedAt': Timestamp.fromDate(v.updatedAt),
    'updatedByDeviceId': v.updatedByDeviceId,
  };

  /// `null` pour une étape inconnue ou un document illisible (`updatedAt` absent/invalide).
  static MedicalVisit? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final stageId = _stages[doc.id];
    final data = doc.data();
    if (stageId == null || data == null) return null;
    if (data['updatedAt'] is! Timestamp) return null;
    final updatedAt = (data['updatedAt'] as Timestamp).toDate();
    final rawVaccines = data['vaccines'];
    return MedicalVisit(
      stageId: stageId,
      appointmentAt: switch (data['appointmentAt']) {
        final Timestamp t => t.toDate(),
        _ => null,
      },
      practitioner: switch (data['practitioner']) {
        final String p => p,
        _ => null,
      },
      doneAt: switch (data['doneAt']) {
        final Timestamp t => t.toDate(),
        _ => null,
      },
      note: switch (data['note']) {
        final String n => n,
        _ => null,
      },
      vaccines: {
        if (rawVaccines is Map<String, dynamic>)
          for (final MapEntry(:key, :value) in rawVaccines.entries)
            if (_vaccines[key] case final code?)
              if (value is Map<String, dynamic>) code: ?_vaccine(value),
      },
      updatedAt: updatedAt,
      updatedByDeviceId: data['updatedByDeviceId'] as String? ?? '',
    );
  }

  /// `null` si `givenAt` est absent ou d'un mauvais type.
  static GivenVaccine? _vaccine(Map<String, dynamic> map) =>
      switch (map['givenAt']) {
        final Timestamp givenAt => GivenVaccine(
          givenAt: givenAt.toDate(),
          brand: map['brand'] as String?,
          lot: map['lot'] as String?,
        ),
        _ => null,
      };
}
