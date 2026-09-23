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

  /// `null` pour un document d'étape inconnue (version plus récente de l'app).
  static MedicalVisit? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final stageId = _stages[doc.id];
    final data = doc.data();
    if (stageId == null || data == null) return null;
    final rawVaccines = data['vaccines'] as Map<String, dynamic>? ?? const {};
    return MedicalVisit(
      stageId: stageId,
      appointmentAt: (data['appointmentAt'] as Timestamp?)?.toDate(),
      practitioner: data['practitioner'] as String?,
      doneAt: (data['doneAt'] as Timestamp?)?.toDate(),
      note: data['note'] as String?,
      vaccines: {
        for (final MapEntry(:key, :value) in rawVaccines.entries)
          ?_vaccines[key]: _vaccine(value as Map<String, dynamic>),
      },
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      updatedByDeviceId: data['updatedByDeviceId'] as String,
    );
  }

  static GivenVaccine _vaccine(Map<String, dynamic> map) => GivenVaccine(
    givenAt: (map['givenAt'] as Timestamp).toDate(),
    brand: map['brand'] as String?,
    lot: map['lot'] as String?,
  );
}
