import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:colette/features/health/domain/entities/custom_vaccine.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';

/// Conversion `CustomAppointment` ↔ document `medicalAppointments/{id}` ; clés absentes plutôt que nulles.
abstract final class CustomAppointmentDto {
  static final _vaccines = VaccineCode.values.asNameMap();

  static Map<String, dynamic> toMap(CustomAppointment a) => {
    'title': a.title,
    'appointmentAt': Timestamp.fromDate(a.appointmentAt),
    'practitioner': ?a.practitioner,
    if (a.doneAt case final at?) 'doneAt': Timestamp.fromDate(at),
    'note': ?a.note,
    if (a.vaccines.isNotEmpty)
      'vaccines': [
        for (final v in a.vaccines)
          {
            if (v.code case final code?) 'code': code.name,
            'name': ?v.name,
            'givenAt': Timestamp.fromDate(v.givenAt),
            'brand': ?v.brand,
            'lot': ?v.lot,
          },
      ],
    'updatedAt': Timestamp.fromDate(a.updatedAt),
    'updatedByDeviceId': a.updatedByDeviceId,
  };

  /// `null` si `title`, `appointmentAt` ou `updatedAt` est absent ou invalide.
  static CustomAppointment? fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return null;
    if (data case {
      'title': final String title,
      'appointmentAt': final Timestamp appointmentAt,
      'updatedAt': final Timestamp updatedAt,
    }) {
      final rawVaccines = data['vaccines'];
      return CustomAppointment(
        id: doc.id,
        title: title,
        appointmentAt: appointmentAt.toDate(),
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
        vaccines: [
          if (rawVaccines is List)
            for (final raw in rawVaccines)
              if (raw is Map<String, dynamic>) ?_vaccine(raw),
        ],
        updatedAt: updatedAt.toDate(),
        updatedByDeviceId: data['updatedByDeviceId'] as String? ?? '',
      );
    }
    return null;
  }

  /// `null` si `givenAt` est invalide ou si ni code connu ni nom n'est présent.
  static CustomVaccine? _vaccine(Map<String, dynamic> map) {
    if (map['givenAt'] is! Timestamp) return null;
    final code = switch (map['code']) {
      final String c => _vaccines[c],
      _ => null,
    };
    final name = switch (map['name']) {
      final String n when n.isNotEmpty => n,
      _ => null,
    };
    if (code == null && name == null) return null;
    return CustomVaccine(
      code: code,
      name: code == null ? name : null,
      givenAt: (map['givenAt'] as Timestamp).toDate(),
      brand: map['brand'] as String?,
      lot: map['lot'] as String?,
    );
  }
}
